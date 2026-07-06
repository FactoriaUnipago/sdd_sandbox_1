# Infrastructure Diagram Template — Reference (Python `diagrams` library)
# pip install diagrams
# Requires: Graphviz installed (https://graphviz.org/download/)

# EXAMPLE 1: AWS Full Stack
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import CloudFront, APIGateway, Route53
from diagrams.aws.compute import Lambda
from diagrams.aws.database import RDS
from diagrams.aws.integration import SQS, SNS
from diagrams.aws.security import Cognito, SecretsManager
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch

with Diagram(
    "AB#100 — Card Payments Infrastructure",
    filename="docs/diagrams/infrastructure",  # outputs .png
    show=False,                                # don't auto-open
    direction="TB",                            # top to bottom
    graph_attr={"bgcolor": "white", "pad": "0.5"},
):
    dns = Route53("payments.example.com")

    with Cluster("AWS — us-east-1"):
        cdn = CloudFront("CDN")

        with Cluster("Frontend"):
            spa = S3("React SPA\nstatic assets")

        with Cluster("API Layer"):
            apigw = APIGateway("REST API\n/api/v1/*")
            authorizer = Lambda("Authorizer\nJWT validation")

        with Cluster("Business Logic"):
            fn_payments = Lambda("Payments\nCRUD + Stripe")
            fn_notifications = Lambda("Notifications\nemail + push")
            fn_reports = Lambda("Reports\naggregations")

        with Cluster("Data"):
            db = RDS("PostgreSQL 16\ndb.t3.medium")
            secrets = SecretsManager("API Keys\nStripe, SES")

        with Cluster("Async"):
            queue = SQS("payment-queue")
            topic = SNS("notifications-topic")

        with Cluster("Auth"):
            cognito = Cognito("User Pool\nJWT issuer")

        monitoring = Cloudwatch("Alarms\nLatency, Errors")

    # Edges
    dns >> cdn
    cdn >> spa
    cdn >> apigw
    apigw >> authorizer >> cognito
    apigw >> fn_payments
    apigw >> fn_reports
    fn_payments >> db
    fn_payments >> secrets
    fn_payments >> Edge(label="async") >> queue
    queue >> fn_notifications
    fn_notifications >> topic
    fn_reports >> db
    fn_payments >> monitoring


# ─────────────────────────────────────────────────────────
# EXAMPLE 2: Azure Full Stack (uncomment to use)
# ─────────────────────────────────────────────────────────
# from diagrams.azure.network import FrontDoor, ApplicationGateway
# from diagrams.azure.compute import FunctionApps
# from diagrams.azure.database import DatabaseForPostgresqlServers
# from diagrams.azure.integration import ServiceBus
# from diagrams.azure.identity import ActiveDirectory
# from diagrams.azure.storage import BlobStorage
#
# with Diagram("Infrastructure — Azure", filename="docs/diagrams/infrastructure", show=False):
#     with Cluster("Azure — East US"):
#         fd = FrontDoor("Front Door")
#         blob = BlobStorage("React SPA")
#         apigw = ApplicationGateway("API Gateway")
#         fn = FunctionApps("Functions")
#         db = DatabaseForPostgresqlServers("PostgreSQL")
#         bus = ServiceBus("Service Bus")
#         ad = ActiveDirectory("Azure AD")
#
#     fd >> blob
#     fd >> apigw >> fn >> db
#     fn >> bus


# ─────────────────────────────────────────────────────────
# EXAMPLE 3: Hybrid (Vercel + AWS + Supabase)
# ─────────────────────────────────────────────────────────
# from diagrams.aws.compute import Lambda
# from diagrams.aws.integration import SQS
# from diagrams.custom import Custom
#
# with Diagram("Infrastructure — Hybrid", filename="docs/diagrams/infrastructure", show=False):
#     vercel = Custom("Vercel\nNext.js", "./icons/vercel.png")
#     supabase = Custom("Supabase\nPostgreSQL + Auth", "./icons/supabase.png")
#
#     with Cluster("AWS"):
#         worker = Lambda("Worker")
#         queue = SQS("Queue")
#
#     vercel >> supabase
#     vercel >> queue >> worker


# ─────────────────────────────────────────────────────────
# EXAMPLE 4: Migration (legacy vs target)
# ─────────────────────────────────────────────────────────
# Generate TWO diagrams for migration projects:
#   filename="docs/diagrams/infrastructure-legacy"
#   filename="docs/diagrams/infrastructure-target"


# ─────────────────────────────────────────────────────────
# RULES
# ─────────────────────────────────────────────────────────
# 1. ALWAYS set show=False (don't auto-open in browser)
# 2. ALWAYS set filename="docs/diagrams/infrastructure" (standard path)
# 3. ALWAYS use Cluster() to group related services (VPC, subnets, layers)
# 4. ALWAYS add brief labels to nodes (service name + purpose)
# 5. ALWAYS use Edge(label="...") for non-obvious connections
# 6. For migration: generate TWO scripts (infrastructure-legacy + infrastructure-target)
# 7. If Python/Graphviz not available → generate Mermaid equivalent in design.md §Infrastructure.
#    Use subgraph clusters (NOT linear flowcharts). Match the same structure as the Python diagram.
#    Example Mermaid fallback for Hybrid (Vercel + AWS):
#
#    ```mermaid
#    graph TB
#        subgraph "Vercel"
#            APP["Next.js App<br/>SSR + API Routes"]
#        end
#        subgraph "AWS — us-east-1"
#            subgraph "Data"
#                RDS["PostgreSQL 15<br/>db.t3.micro"]
#            end
#            subgraph "Async"
#                SQS["SQS Queue"]
#                WORKER["Lambda Worker"]
#            end
#        end
#        APP -->|"Prisma ORM"| RDS
#        APP -->|"async jobs"| SQS --> WORKER
#    ```
#
#    Rules for Mermaid fallback:
#    - Use `subgraph` for every Cluster() in the Python version
#    - Add `<br/>` for multi-line labels (name + purpose)
#    - Use labeled edges for non-obvious connections
#    - Do NOT use plain A --> B --> C flowcharts — show architecture, not request flow
# 8. Detect cloud provider from stacks[] in .sdd-config.json:
#    - "aws" → use diagrams.aws.*
#    - "azure" → use diagrams.azure.*
#    - "gcp" → use diagrams.gcp.*
#    - mixed → use diagrams.custom.Custom for unsupported services
# 9. Include monitoring/observability nodes (CloudWatch, Datadog, etc.)
# 10. Include security nodes (auth, secrets management)
