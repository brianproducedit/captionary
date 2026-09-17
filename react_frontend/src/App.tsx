import { Navigate, Route, Routes } from 'react-router-dom';
import { MainLayout } from './layouts/MainLayout';
import { AboutProject } from './pages/AboutProject';
import { DonatePage } from './pages/DonatePage';
import { DownloadPage } from './pages/DownloadPage';
import { PaymentConfirmation } from './pages/PaymentConfirmation';

function App() {
  return (
    <div className="min-h-screen antialiased selection:bg-primary-container selection:text-on-primary-container"
         style={{ backgroundColor: 'var(--color-surface)', fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface)' }}>
      <Routes>
        <Route path="/" element={<MainLayout />}>
          <Route index element={<DonatePage />} />
          <Route path="download" element={<DownloadPage />} />
          <Route path="downloads" element={<Navigate to="/download" replace />} />
          <Route path="donate" element={<DonatePage />} />
          <Route path="support" element={<Navigate to="/donate" replace />} />
          <Route path="about" element={<AboutProject />} />
          <Route path="payment-confirmation" element={<PaymentConfirmation />} />
        </Route>
      </Routes>
    </div>
  );
}

export default App;
