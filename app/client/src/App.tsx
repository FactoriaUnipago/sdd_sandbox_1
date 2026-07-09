import './App.css'


function App() {
  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px' }}>
      <div className="card" style={{ maxWidth: '480px', width: '100%', textAlign: 'center' }}>
        <h1 style={{ marginBottom: '8px', color: 'var(--theme-primary)' }}>Task Manager</h1>
        <p style={{ color: 'var(--theme-text-secondary)', marginBottom: '24px' }}>
          Monorepo inicializado con el tema <strong>Corporate</strong>
        </p>

        <div style={{ display: 'flex', gap: '12px', justifyContent: 'center', marginBottom: '24px' }}>
          <button className="btn btn-primary">Iniciar Sesión</button>
          <button className="btn btn-secondary">Ver Documentación</button>
        </div>

        <hr style={{ border: 'none', borderTop: '1px solid var(--theme-border-default)', margin: '24px 0' }} />

        <div style={{ textAlign: 'left', fontSize: '14px' }}>
          <h3 style={{ fontSize: '16px', marginBottom: '12px' }}>Tokens de Diseño Activos:</h3>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <li>🎨 <strong>Primary Color:</strong> <code style={{ color: 'var(--theme-primary)' }}>#1E40AF</code></li>
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
