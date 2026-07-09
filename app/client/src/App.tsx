import './index.css'

function App() {
  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-theme-page font-sans">
      <div className="max-w-md w-full text-center bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6">
        <h1 className="text-3xl font-bold tracking-tight text-primary mb-2 font-headings">Task Manager</h1>
        <p className="text-slate-500 mb-6">
          Monorepo inicializado con el tema <strong>Corporate</strong> usando TailwindCSS 4
        </p>

        <div className="flex gap-3 justify-center mb-6">
          <button className="bg-gradient-to-r from-primary to-primary-dark text-white font-medium py-2 px-4 rounded-lg hover:opacity-95 transition-all">
            Iniciar Sesión
          </button>
          <button className="bg-white border border-slate-200 text-slate-900 font-medium py-2 px-4 rounded-lg hover:bg-theme-input transition-all">
            Ver Documentación
          </button>
        </div>

        <hr className="border-t border-slate-100 my-6" />

        <div className="text-left text-sm">
          <h3 className="text-base font-semibold mb-3 font-headings">Tokens de Diseño Activos:</h3>
          <ul className="space-y-2 text-slate-600">
            <li>🎨 <strong>Primary Color:</strong> <code className="text-primary font-mono font-semibold">#1E40AF</code></li>
            <li>✍️ <strong>Fuentes:</strong> Inter & Plus Jakarta Sans</li>
            <li>🛡️ <strong>API Key Gate:</strong> Activo (/api/health)</li>
            <li>📖 <strong>Interactive Docs:</strong> Swagger UI (/api/docs)</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

export default App
