import { useTranslation, Trans } from 'react-i18next';
import './index.css';

function App() {
  const { t, i18n } = useTranslation();

  const toggleLanguage = () => {
    const nextLang = i18n.language === 'es' ? 'en' : 'es';
    i18n.changeLanguage(nextLang);
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-theme-page font-sans">
      <div className="max-w-md w-full text-center bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 relative">
        {/* Language selector toggle */}
        <button 
          onClick={toggleLanguage}
          className="absolute top-4 right-4 bg-slate-100 hover:bg-slate-200 text-xs font-semibold px-2 py-1 rounded transition-colors"
        >
          {i18n.language === 'es' ? 'EN' : 'ES'}
        </button>

        <h1 className="text-3xl font-bold tracking-tight text-primary mb-2 font-headings">
          {t('app.title')}
        </h1>
        <p className="text-slate-500 mb-6 text-sm">
          <Trans i18nKey="app.subtitle">
            Proyecto inicializado con el tema <strong>Corporate</strong> usando TailwindCSS 4
          </Trans>
        </p>

        <div className="flex gap-3 justify-center mb-6">
          <button className="bg-gradient-to-r from-primary to-primary-dark text-white font-medium py-2 px-4 rounded-lg hover:opacity-95 transition-all text-sm">
            {t('auth.login')}
          </button>
          <button className="bg-white border border-slate-200 text-slate-900 font-medium py-2 px-4 rounded-lg hover:bg-theme-input transition-all text-sm">
            {t('app.viewDocs')}
          </button>
        </div>

        <hr className="border-t border-slate-100 my-6" />

        <div className="text-left text-sm">
          <h3 className="text-base font-semibold mb-3 font-headings">
            {t('tokens.title')}
          </h3>
          <ul className="space-y-2 text-slate-600">
            <li>
              🎨 <strong>{t('tokens.primaryColor')}:</strong> <code className="text-primary font-mono font-semibold">#1E40AF</code>
            </li>
            <li>
              ✍️ <strong>{t('tokens.fonts')}:</strong> Inter & Plus Jakarta Sans
            </li>
            <li>
              🛡️ <strong>{t('tokens.apiKeyGate')}:</strong> {t('tokens.active')} (/api/health)
            </li>
            <li>
              📖 <strong>{t('tokens.interactiveDocs')}:</strong> Swagger UI (/api/docs)
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default App;
