import './App.css'

function App() {
  return (
    <div className="app-container">
      <div className="card card-container">
        <h1 className="title">Task Manager</h1>
        <p className="subtitle">
          Monorepo inicializado con el tema <strong>Corporate</strong>
        </p>

        <div className="button-group">
          <button className="btn btn-primary">Iniciar Sesión</button>
          <button className="btn btn-secondary">Ver Documentación</button>
        </div>

        <hr className="divider" />

        <div className="list-container">
          <h3 className="list-title">Tokens de Diseño Activos:</h3>
          <ul className="token-list">
            <li className="token-list-item">🎨 <strong>Primary Color:</strong> <code>#1E40AF</code></li>
            <li className="token-list-item">✍️ <strong>Fuentes:</strong> Inter & Plus Jakarta Sans</li>
            <li className="token-list-item">🛡️ <strong>API Key Gate:</strong> Activo (/api/health)</li>
            <li className="token-list-item">📖 <strong>Interactive Docs:</strong> Swagger UI (/api/docs)</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

export default App
