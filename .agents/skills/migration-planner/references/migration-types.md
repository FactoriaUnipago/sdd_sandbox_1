# Migration Types (Detail)

### Technology change
| Type | Example | Complexity |
|------|---------|:-----------:|
| Framework | Angular → React, Express → Fastify, jQuery → Vue | 🟡 Medium |
| Language | Java → TypeScript, PHP → Python, JS → TypeScript | 🔴 High |
| Database | Oracle → PostgreSQL, MySQL → DynamoDB | 🔴 High |
| ORM | Sequelize → Prisma, Hibernate → TypeORM | 🟡 Medium |

### Version upgrade
| Type | Example | Complexity |
|------|---------|:-----------:|
| Framework version | Angular 14→20, React 16→18, Next 12→14 | 🟡 Medium |
| Runtime version | Node 14→20, Python 3.8→3.12, Java 8→21 | 🟢 Low |
| Dependency upgrade | Webpack→Vite, CRA→Vite, Yarn→pnpm | 🟢 Low |

### Infrastructure and architecture
| Type | Example | Complexity |
|------|---------|:-----------:|
| Cloud | On-premise → AWS, AWS → Azure, Azure → GCP | 🔴 High |
| Serverless | EC2 → Lambda, ECS → Lambda, VM → Functions | 🟡 Medium |
| Architecture | Monolith → Microservices, MVC → Clean Architecture | 🔴 High |
| Containerization | Bare metal → Docker, Docker Compose → ECS/EKS | 🟡 Medium |
| CI/CD | Jenkins → GitHub Actions, CircleCI → Azure Pipelines | 🟢 Low |

### API and communication
| Type | Example | Complexity |
|------|---------|:-----------:|
| API Protocol | SOAP → REST, REST → GraphQL | 🟡 Medium |
| Communication | HTTP polling → WebSocket/SSE, REST sync → Event-driven | 🟡 Medium |

### Frontend
| Type | Example | Complexity |
|------|---------|:-----------:|
| CSS/Styling | SASS → CSS Modules, CSS-in-JS → Tailwind, Bootstrap → Design system | 🟢 Low |
| State management | Redux → Zustand, MobX → TanStack Query | 🟢 Low |
| Build system | Webpack → Vite, Grunt → esbuild | 🟢 Low |
| Testing framework | Jasmine → Jest, Mocha → Vitest, Protractor → Playwright | 🟢 Low |

### Security and auth
| Type | Example | Complexity |
|------|---------|:-----------:|
| Authentication | Custom auth → OAuth2/Cognito, LDAP → SSO | 🟡 Medium |

### Organization
| Type | Example | Complexity |
|------|---------|:-----------:|
| Repository | Multi-repo → Monorepo (Nx/Turborepo) | 🟡 Medium |
| Storage | Local files → S3, FTP → CloudFront+S3 | 🟢 Low |
