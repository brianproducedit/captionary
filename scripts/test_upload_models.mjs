import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import {
  parseArgs,
  loadRootEnv,
  sha256,
  readMetadata,
  validateModel,
  getS3Client,
} from './upload_models.js';

describe('upload_models.js tooling', () => {
  let tempDir;

  before(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'upload_models_test_'));
  });

  after(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  describe('parseArgs', () => {
    it('parses defaults correctly', () => {
      const options = parseArgs([]);
      assert.equal(options.dryRun, false);
      assert.equal(options.manifestOnly, false);
      assert.equal(options.verify, false);
      assert.equal(options.replace, false);
      assert.equal(options.applyCors, false);
      assert.equal(options.envFile, null);
    });

    it('parses flags correctly', () => {
      const options = parseArgs([
        '--dry-run',
        '--manifest-only',
        '--verify',
        '--replace',
        '--apply-cors',
        '--env',
        '.env.custom',
      ]);
      assert.equal(options.dryRun, true);
      assert.equal(options.manifestOnly, true);
      assert.equal(options.verify, true);
      assert.equal(options.replace, true);
      assert.equal(options.applyCors, true);
      assert.match(options.envFile, /\.env\.custom$/);
    });

    it('throws on unknown argument', () => {
      assert.throws(() => parseArgs(['--unknown-flag']), /Unknown argument: --unknown-flag/);
    });
  });

  describe('sha256', () => {
    it('computes accurate SHA256 hex digest for file content', () => {
      const filePath = join(tempDir, 'test_file.bin');
      writeFileSync(filePath, 'captionary-whisper-test-data');

      const digest = sha256(filePath);
      // echo -n "captionary-whisper-test-data" | sha256sum
      // Expected: b2495bb6f4f25b3e944747ebc7936a18d9eeff5db2a5433246bc6d302a24c552
      assert.equal(digest.length, 64);
      assert.match(digest, /^[a-f0-9]{64}$/);
    });
  });

  describe('readMetadata', () => {
    it('reads valid metadata sidecar successfully', () => {
      const binPath = join(tempDir, 'model.bin');
      const sidecarPath = `${binPath}.json`;
      const validMeta = {
        id: 'tiny.en',
        engine: 'whisper_flutter_new',
        language_codes: ['en'],
        display_name: 'English Tiny',
        quantization: 'none',
        bundled: true,
        min_android_sdk: 21,
        recommended_ram_gb: 4,
        license: 'MIT',
        source_url: 'https://example.com',
      };
      writeFileSync(binPath, 'dummy binary');
      writeFileSync(sidecarPath, JSON.stringify(validMeta));

      const parsed = readMetadata(binPath);
      assert.equal(parsed.id, 'tiny.en');
      assert.deepEqual(parsed.language_codes, ['en']);
    });

    it('throws if sidecar is missing', () => {
      assert.throws(
        () => readMetadata(join(tempDir, 'non_existent.bin')),
        /Missing metadata sidecar/,
      );
    });

    it('throws if required field is missing', () => {
      const binPath = join(tempDir, 'incomplete.bin');
      writeFileSync(binPath, 'content');
      writeFileSync(`${binPath}.json`, JSON.stringify({ id: 'tiny.en' }));

      assert.throws(
        () => readMetadata(binPath),
        /is missing required field/,
      );
    });

    it('throws if language_codes is not a non-empty array', () => {
      const binPath = join(tempDir, 'bad_lang.bin');
      writeFileSync(binPath, 'content');
      writeFileSync(`${binPath}.json`, JSON.stringify({
        id: 'tiny.en',
        engine: 'whisper_flutter_new',
        language_codes: [],
        display_name: 'English Tiny',
        quantization: 'none',
        bundled: true,
        min_android_sdk: 21,
        recommended_ram_gb: 4,
        license: 'MIT',
        source_url: 'https://example.com',
      }));

      assert.throws(
        () => readMetadata(binPath),
        /language_codes must be a non-empty array/,
      );
    });
  });

  describe('validateModel', () => {
    it('accepts valid model structure', () => {
      assert.doesNotThrow(() => {
        validateModel({
          id: 'tiny.en',
          file: 'models/ggml-tiny.en.bin',
          sha256: 'a'.repeat(64),
          size_bytes: 1024,
        });
      });
    });

    it('rejects path traversal in model file path', () => {
      assert.throws(() => {
        validateModel({
          id: 'evil',
          file: 'models/../evil.bin',
          sha256: 'a'.repeat(64),
          size_bytes: 1024,
        });
      }, /Invalid model path/);
    });

    it('rejects non-64-character or uppercase SHA256', () => {
      assert.throws(() => {
        validateModel({
          id: 'test',
          file: 'models/valid.bin',
          sha256: 'A'.repeat(64), // uppercase
          size_bytes: 1024,
        });
      }, /Invalid SHA256/);

      assert.throws(() => {
        validateModel({
          id: 'test',
          file: 'models/valid.bin',
          sha256: 'short-sha',
          size_bytes: 1024,
        });
      }, /Invalid SHA256/);
    });

    it('rejects non-positive size_bytes', () => {
      assert.throws(() => {
        validateModel({
          id: 'test',
          file: 'models/valid.bin',
          sha256: 'a'.repeat(64),
          size_bytes: 0,
        });
      }, /Invalid size/);
    });
  });

  describe('getS3Client credential validation', () => {
    it('throws helpful error if required environment variables are missing', async () => {
      const orig = { ...process.env };
      delete process.env.R2_ACCOUNT_ID;
      delete process.env.R2_ACCESS_KEY_ID;
      delete process.env.R2_SECRET_ACCESS_KEY;
      delete process.env.R2_BUCKET;

      try {
        await assert.rejects(
          async () => {
            await getS3Client();
          },
          /Missing required environment variable\(s\): R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET/,
        );
      } finally {
        Object.assign(process.env, orig);
      }
    });
  });
});
