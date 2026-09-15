import { createHash } from 'node:crypto';
import dns from 'node:dns';
import { createReadStream, existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, dirname, extname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

// Patch dns.lookup to fall back to dns.resolve4 with Google DNS when the
// OS-level resolver (getaddrinfo) fails. Node's HTTP stack uses getaddrinfo
// by default, which ignores dns.setServers(). This fallback ensures R2 S3 API
// endpoints resolve even when the system DNS is unreliable.
const _originalLookup = dns.lookup;
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);
dns.lookup = function lookupWithFallback(hostname, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }
  if (typeof options === 'number') {
    options = { family: options };
  }
  _originalLookup.call(dns, hostname, options, (err, address, family) => {
    if (!err) return callback(null, address, family);
    // OS resolver failed — try dns.resolve4 which uses our custom servers
    dns.resolve4(hostname, (resolveErr, addresses) => {
      if (resolveErr) return callback(err); // return original error
      callback(null, addresses[0], 4);
    });
  });
};

const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDir, '..');

function printHelp() {
  console.log(`Captionary R2 model tool

Usage:
  node scripts/upload_models.js [options]

Options:
  --models-dir <path>    Model input directory. Default: models
  --manifest <path>      Manifest output path. Default: r2/manifest.json
  --env <path>           Path to env file. Default: .env.production or .env
  --apply-cors           Apply r2/cors.json rules to the bucket
  --dry-run              Hash and validate without writing or uploading
  --manifest-only        Write manifest/checksums locally without uploading
  --verify               Verify published objects with HEAD requests
  --replace              Allow replacing existing R2 objects
  --help                 Show this help

Each model file must have a sidecar file named <model>.bin.json containing
language_codes, display_name, quantization, bundled, min_android_sdk,
recommended_ram_gb, license, and source_url.`);
}

function parseArgs(argv) {
  const options = {
    modelsDir: join(repoRoot, 'models'),
    manifestPath: join(repoRoot, 'r2', 'manifest.json'),
    envFile: null,
    applyCors: false,
    dryRun: false,
    manifestOnly: false,
    verify: false,
    replace: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--help') {
      printHelp();
      process.exit(0);
    }
    if (argument === '--dry-run') options.dryRun = true;
    else if (argument === '--manifest-only') options.manifestOnly = true;
    else if (argument === '--verify') options.verify = true;
    else if (argument === '--replace') options.replace = true;
    else if (argument === '--apply-cors') options.applyCors = true;
    else if (argument === '--models-dir') options.modelsDir = resolve(repoRoot, argv[++index]);
    else if (argument === '--manifest') options.manifestPath = resolve(repoRoot, argv[++index]);
    else if (argument === '--env') options.envFile = resolve(repoRoot, argv[++index]);
    else throw new Error(`Unknown argument: ${argument}`);
  }
  return options;
}

function loadRootEnv(customEnvPath = null) {
  const candidates = customEnvPath
    ? [resolve(repoRoot, customEnvPath)]
    : [join(repoRoot, '.env.production'), join(repoRoot, '.env')];

  for (const envPath of candidates) {
    if (!existsSync(envPath)) continue;
    for (const rawLine of readFileSync(envPath, 'utf8').split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#')) continue;
      const separator = line.indexOf('=');
      if (separator < 1) continue;
      const key = line.slice(0, separator).trim();
      const value = line.slice(separator + 1).trim().replace(/^['"]|['"]$/g, '');
      if (!process.env[key]) process.env[key] = value;
    }
  }
}

function collectFiles(directory) {
  if (!existsSync(directory)) throw new Error(`Model directory does not exist: ${directory}`);
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const entryPath = join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Symlinks are not allowed: ${entryPath}`);
    if (entry.isDirectory()) files.push(...collectFiles(entryPath));
    else if (entry.isFile() && extname(entry.name).toLowerCase() === '.bin') files.push(entryPath);
  }
  return files.sort();
}

function sha256(filePath) {
  const hash = createHash('sha256');
  hash.update(readFileSync(filePath));
  return hash.digest('hex');
}

function readMetadata(filePath) {
  const metadataPath = `${filePath}.json`;
  if (!existsSync(metadataPath)) throw new Error(`Missing metadata sidecar: ${metadataPath}`);
  const metadata = JSON.parse(readFileSync(metadataPath, 'utf8'));
  const required = [
    'id',
    'engine',
    'language_codes',
    'display_name',
    'quantization',
    'bundled',
    'min_android_sdk',
    'recommended_ram_gb',
    'license',
    'source_url',
  ];
  for (const field of required) {
    if (metadata[field] === undefined || metadata[field] === null || metadata[field] === '') {
      throw new Error(`${metadataPath} is missing required field: ${field}`);
    }
  }
  if (!Array.isArray(metadata.language_codes) || metadata.language_codes.length === 0) {
    throw new Error(`${metadataPath} language_codes must be a non-empty array`);
  }
  return metadata;
}

function buildManifest(options) {
  const models = collectFiles(options.modelsDir).map((filePath) => {
    const metadata = readMetadata(filePath);
    const relativeFile = relative(options.modelsDir, filePath).split(sep).join('/');
    const file = `models/${relativeFile}`;
    const model = {
      ...metadata,
      file,
      size_bytes: statSync(filePath).size,
      sha256: sha256(filePath),
    };
    validateModel(model);
    return { filePath, model };
  });

  if (models.length === 0) throw new Error(`No .bin files found in ${options.modelsDir}`);
  const baseUrl = (process.env.R2_PUBLIC_BASE_URL || 'https://models.example.com/').replace(/\/+$/, '/');
  return {
    manifest: {
      schema_version: 1,
      catalog_version: 1,
      updated_at: new Date().toISOString(),
      base_url: baseUrl,
      default_language: 'en',
      models: models.map(({ model }) => model),
    },
    models,
  };
}

function validateModel(model) {
  if (!/^models\/[a-zA-Z0-9._/-]+$/.test(model.file) || model.file.includes('..')) {
    throw new Error(`Invalid model path: ${model.file}`);
  }
  if (!/^[a-f0-9]{64}$/.test(model.sha256)) throw new Error(`Invalid SHA256 for ${model.id}`);
  if (!Number.isInteger(model.size_bytes) || model.size_bytes <= 0) throw new Error(`Invalid size for ${model.id}`);
}

function writeLocalOutputs(options, manifest, models) {
  if (options.dryRun) return;
  const manifestDir = dirname(options.manifestPath);
  const checksumPath = join(manifestDir, 'checksums.sha256');
  writeFileSync(options.manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  writeFileSync(
    checksumPath,
    `${models.map(({ model }) => `${model.sha256}  ${model.file}`).sort().join('\n')}\n`,
  );
}

async function getS3Client() {
  const { S3Client } = await import('@aws-sdk/client-s3');
  const required = ['R2_ACCOUNT_ID', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_BUCKET'];
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required environment variable(s): ${missing.join(', ')}`);
  }
  return {
    client: new S3Client({
      region: 'auto',
      endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID,
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
      },
      forcePathStyle: true,
    }),
    bucket: process.env.R2_BUCKET,
  };
}

async function applyCorsConfiguration(corsConfigPath) {
  const { PutBucketCorsCommand } = await import('@aws-sdk/client-s3');
  const { client, bucket } = await getS3Client();
  const rawCors = readFileSync(corsConfigPath, 'utf8');
  const corsRules = JSON.parse(rawCors);
  await client.send(
    new PutBucketCorsCommand({
      Bucket: bucket,
      CORSConfiguration: {
        CORSRules: corsRules,
      },
    }),
  );
  console.log(`Applied CORS rules from ${corsConfigPath} to bucket ${bucket}`);
}

async function upload(options, manifest, models) {
  const {
    PutObjectCommand, HeadObjectCommand,
    CreateMultipartUploadCommand, UploadPartCommand, CompleteMultipartUploadCommand,
    AbortMultipartUploadCommand,
  } = await import('@aws-sdk/client-s3');
  const { client, bucket } = await getS3Client();
  const PART_SIZE = 8 * 1024 * 1024; // 8 MB chunks

  for (const { filePath, model } of models) {
    try {
      await client.send(new HeadObjectCommand({ Bucket: bucket, Key: model.file }));
      if (!options.replace) throw new Error(`Object exists; use --replace to overwrite: ${model.file}`);
    } catch (error) {
      if (error.name !== 'NotFound' && !String(error).includes('NotFound')) throw error;
    }
    const fileBuffer = readFileSync(filePath);
    if (fileBuffer.length <= PART_SIZE) {
      // Small file — single PutObject
      await client.send(new PutObjectCommand({
        Bucket: bucket,
        Key: model.file,
        Body: fileBuffer,
        ContentLength: fileBuffer.length,
        ContentType: 'application/octet-stream',
        Metadata: { sha256: model.sha256 },
      }));
    } else {
      // Large file — multipart upload
      console.log(`Starting multipart upload for ${model.file} (${fileBuffer.length} bytes, ${Math.ceil(fileBuffer.length / PART_SIZE)} parts)...`);
      const { UploadId } = await client.send(new CreateMultipartUploadCommand({
        Bucket: bucket,
        Key: model.file,
        ContentType: 'application/octet-stream',
        Metadata: { sha256: model.sha256 },
      }));
      const parts = [];
      try {
        for (let partNumber = 1, offset = 0; offset < fileBuffer.length; partNumber++, offset += PART_SIZE) {
          const end = Math.min(offset + PART_SIZE, fileBuffer.length);
          const partBody = fileBuffer.subarray(offset, end);
          const { ETag } = await client.send(new UploadPartCommand({
            Bucket: bucket,
            Key: model.file,
            UploadId,
            PartNumber: partNumber,
            Body: partBody,
            ContentLength: partBody.length,
          }));
          parts.push({ ETag, PartNumber: partNumber });
          console.log(`  Part ${partNumber}/${Math.ceil(fileBuffer.length / PART_SIZE)} uploaded (${partBody.length} bytes)`);
        }
        await client.send(new CompleteMultipartUploadCommand({
          Bucket: bucket,
          Key: model.file,
          UploadId,
          MultipartUpload: { Parts: parts },
        }));
      } catch (uploadErr) {
        // Abort the multipart upload on failure to avoid orphaned parts
        await client.send(new AbortMultipartUploadCommand({ Bucket: bucket, Key: model.file, UploadId })).catch(() => {});
        throw uploadErr;
      }
    }
    console.log(`Uploaded ${model.file} (${fileBuffer.length} bytes)`);
  }
  const manifestBuffer = Buffer.from(JSON.stringify(manifest, null, 2));
  await client.send(new PutObjectCommand({
    Bucket: bucket,
    Key: 'manifest.json',
    Body: manifestBuffer,
    ContentLength: manifestBuffer.length,
    ContentType: 'application/json',
  }));
  const checksumBuffer = Buffer.from(`${models.map(({ model }) => `${model.sha256}  ${model.file}`).sort().join('\n')}\n`);
  await client.send(new PutObjectCommand({
    Bucket: bucket,
    Key: 'checksums.sha256',
    Body: checksumBuffer,
    ContentLength: checksumBuffer.length,
    ContentType: 'text/plain',
  }));
  console.log('Uploaded manifest.json and checksums.sha256');
}

async function verifyRemote(models) {
  const { HeadObjectCommand } = await import('@aws-sdk/client-s3');
  const { client, bucket } = await getS3Client();
  for (const { model } of models) {
    await client.send(new HeadObjectCommand({ Bucket: bucket, Key: model.file }));
    console.log(`Verified ${model.file}`);
  }
  await client.send(new HeadObjectCommand({ Bucket: bucket, Key: 'manifest.json' }));
  console.log('Verified manifest.json');
  await client.send(new HeadObjectCommand({ Bucket: bucket, Key: 'checksums.sha256' }));
  console.log('Verified checksums.sha256');
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  loadRootEnv(options.envFile);

  if (options.applyCors) {
    const corsPath = join(repoRoot, 'r2', 'cors.json');
    await applyCorsConfiguration(corsPath);
    if (!existsSync(options.modelsDir)) {
      return;
    }
  }

  const { manifest, models } = buildManifest(options);
  writeLocalOutputs(options, manifest, models);
  console.log(`Validated ${models.length} model(s).`);
  if (options.dryRun || options.manifestOnly) return;
  if (options.verify) await verifyRemote(models);
  else await upload(options, manifest, models);
}

const isDirectExecution = process.argv[1] && (
  resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url))
);

if (isDirectExecution) {
  main().catch((error) => {
    console.error(`R2 model tool failed: ${error.message}`);
    process.exitCode = 1;
  });
}

export {
  parseArgs,
  loadRootEnv,
  collectFiles,
  sha256,
  readMetadata,
  buildManifest,
  validateModel,
  getS3Client,
  applyCorsConfiguration,
  upload,
  verifyRemote,
  main,
};
