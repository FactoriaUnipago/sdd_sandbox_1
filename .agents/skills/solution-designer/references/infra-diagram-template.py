# Infrastructure Diagram Template — Reference (Python `diagrams` library)
# pip install diagrams
# Requires: Graphviz installed (https://graphviz.org/download/)

# ─────────────────────────────────────────────────────────
# STYLING STANDARD — Use these for ALL infrastructure diagrams
# ─────────────────────────────────────────────────────────

GRAPH_ATTR = {
    "bgcolor": "#ffffff",
    "pad": "1.2",
    "fontsize": "18",
    "fontname": "Helvetica Neue",
    "fontcolor": "#1a1a2e",
    "splines": "curved",
    "nodesep": "1.0",
    "ranksep": "1.0",
    "dpi": "150",
}

# Cluster styles — pick by provider/purpose
CLUSTER_VERCEL = {
    "bgcolor": "#f0f7ff",
    "style": "rounded",
    "pencolor": "#0070f3",
    "penwidth": "2.5",
    "fontname": "Helvetica Neue Bold",
    "fontsize": "15",
    "fontcolor": "#0050b3",
}

CLUSTER_AWS = {
    "bgcolor": "#fff8f0",
    "style": "rounded",
    "pencolor": "#ff9900",
    "penwidth": "2.5",
    "fontname": "Helvetica Neue Bold",
    "fontsize": "15",
    "fontcolor": "#cc7a00",
}

CLUSTER_AZURE = {
    "bgcolor": "#f0f4ff",
    "style": "rounded",
    "pencolor": "#0078d4",
    "penwidth": "2.5",
    "fontname": "Helvetica Neue Bold",
    "fontsize": "15",
    "fontcolor": "#005a9e",
}

CLUSTER_SECURITY = {
    "bgcolor": "#fffbf0",
    "style": "rounded",
    "pencolor": "#d4a017",
    "penwidth": "2",
    "fontname": "Helvetica Neue Bold",
    "fontsize": "13",
    "fontcolor": "#8a6d00",
}

CLUSTER_INNER = {
    "bgcolor": "#ffffff",
    "style": "rounded",
    "pencolor": "#d0d7de",
    "penwidth": "1.5",
    "fontname": "Helvetica Neue",
    "fontsize": "12",
    "fontcolor": "#57606a",
}

CLUSTER_LOCAL = {
    "bgcolor": "#f0fff4",
    "style": "rounded",
    "pencolor": "#2da44e",
    "penwidth": "2.5",
    "fontname": "Helvetica Neue Bold",
    "fontsize": "15",
    "fontcolor": "#1a7f37",
}

CLUSTER_ONPREM = {
    "bgcolor": "#f5f5f5",
    "style": "rounded",
    "pencolor": "#666666",
    "penwidth": "2.5",
    "fontname": "Helvetica Neue Bold",
    "fontsize": "15",
    "fontcolor": "#333333",
}

# Edge styles by purpose
# Primary flow:    Edge(color="#0070f3", style="bold", label="HTTPS")
# Auth/security:   Edge(color="#d4a017", style="bold", label="✓ JWT")
# Database:        Edge(color="#7c3aed", style="bold", label="Prisma ORM\nTCP :5432")
# Internal/async:  Edge(style="dashed", color="#999999", label="metrics")
# API calls:       Edge(color="#666666", label="fetch /api/*")
# Dev env:         Edge(color="#2da44e", style="bold", label="localhost:3000")


# ─────────────────────────────────────────────────────────
# EXAMPLE 1: AWS Full Stack (Serverless)
# ─────────────────────────────────────────────────────────
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import CloudFront, APIGateway, Route53
from diagrams.aws.compute import Lambda
from diagrams.aws.database import RDS
from diagrams.aws.integration import SQS, SNS
from diagrams.aws.security import Cognito, SecretsManager
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch

with Diagram(
    "",
    filename="docs/diagrams/infrastructure",
    show=False,
    direction="LR",
    graph_attr=GRAPH_ATTR,
):
    dns = Route53("payments.example.com")

    with Cluster("AWS — us-east-1", graph_attr=CLUSTER_AWS):
        cdn = CloudFront("CDN")

        with Cluster("Frontend", graph_attr=CLUSTER_INNER):
            spa = S3("React SPA\nstatic assets")

        with Cluster("API Layer", graph_attr=CLUSTER_INNER):
            apigw = APIGateway("REST API\n/api/v1/*")
            authorizer = Lambda("Authorizer\nJWT validation")

        with Cluster("Business Logic", graph_attr=CLUSTER_INNER):
            fn_payments = Lambda("Payments\nCRUD + Stripe")
            fn_notifications = Lambda("Notifications\nemail + push")
            fn_reports = Lambda("Reports\naggregations")

        with Cluster("Data", graph_attr=CLUSTER_INNER):
            db = RDS("PostgreSQL 16\ndb.t3.medium")
            secrets = SecretsManager("API Keys\nStripe, SES")

        with Cluster("Async", graph_attr=CLUSTER_INNER):
            queue = SQS("payment-queue")
            topic = SNS("notifications-topic")

        with Cluster("Auth", graph_attr=CLUSTER_SECURITY):
            cognito = Cognito("User Pool\nJWT issuer")

        monitoring = Cloudwatch("Alarms\nLatency, Errors")

    # Edges with styled connections
    dns >> Edge(color="#0070f3", style="bold", label="HTTPS") >> cdn
    cdn >> Edge(color="#0070f3") >> spa
    cdn >> Edge(color="#0070f3") >> apigw
    apigw >> Edge(color="#d4a017", style="bold", label="✓ JWT") >> authorizer >> cognito
    apigw >> Edge(color="#666666") >> fn_payments
    apigw >> Edge(color="#666666") >> fn_reports
    fn_payments >> Edge(color="#7c3aed", style="bold", label="TCP :5432") >> db
    fn_payments >> Edge(color="#666666") >> secrets
    fn_payments >> Edge(style="dashed", color="#999999", label="async") >> queue
    queue >> fn_notifications
    fn_notifications >> topic
    fn_reports >> Edge(color="#7c3aed", style="bold") >> db
    fn_payments >> Edge(style="dashed", color="#999999", label="metrics") >> monitoring


# ─────────────────────────────────────────────────────────
# EXAMPLE 2: Vercel + AWS Hybrid (Full Stack App)
# ─────────────────────────────────────────────────────────
# from diagrams.onprem.client import Users
# from diagrams.programming.framework import React
# from diagrams.programming.language import NodeJS
# from diagrams.aws.database import RDS
# from diagrams.aws.security import IAM
# from diagrams.aws.management import Cloudwatch
# from diagrams.onprem.security import Vault
# from diagrams.generic.network import Firewall
# from diagrams.saas.cdn import Cloudflare
#
# with Diagram("", filename="docs/diagrams/infrastructure", show=False,
#              direction="LR", graph_attr=GRAPH_ATTR):
#     users = Users("Users")
#
#     with Cluster("Vercel Platform", graph_attr=CLUSTER_VERCEL):
#         with Cluster("Edge Network", graph_attr=CLUSTER_INNER):
#             edge = Cloudflare("CDN + SSL")
#         with Cluster("Frontend", graph_attr=CLUSTER_INNER):
#             react = React("React SPA")
#         with Cluster("Security", graph_attr=CLUSTER_SECURITY):
#             apikey = Firewall("API Key Gate")
#             jwt = Vault("JWT Middleware")
#         with Cluster("API", graph_attr=CLUSTER_INNER):
#             api = NodeJS("Express API\n/api/*")
#
#     with Cluster("AWS — us-east-1", graph_attr=CLUSTER_AWS):
#         with Cluster("VPC — Private Subnet", graph_attr=CLUSTER_INNER):
#             db = RDS("PostgreSQL 16\ndb.t3.micro")
#         iam = IAM("IAM Credentials")
#         cw = Cloudwatch("CloudWatch\nMetrics")
#
#     users >> Edge(color="#0070f3", style="bold", label="HTTPS") >> edge
#     edge >> react
#     react >> Edge(color="#666666", label="fetch /api/*") >> apikey
#     apikey >> Edge(color="#d4a017", style="bold", label="✓ valid key") >> jwt
#     jwt >> Edge(color="#d4a017", style="bold", label="✓ userId") >> api
#     api >> Edge(color="#7c3aed", style="bold", label="Prisma ORM\nTCP :5432") >> db
#     iam >> Edge(style="dashed", color="#999999", label="rotate\ncredentials") >> db
#     db >> Edge(style="dashed", color="#999999", label="metrics") >> cw


# ─────────────────────────────────────────────────────────
# EXAMPLE 3: Migration (legacy vs target)
# ─────────────────────────────────────────────────────────
# Generate TWO diagrams for migration projects:
#   filename="docs/diagrams/infrastructure-legacy"   (use CLUSTER_ONPREM)
#   filename="docs/diagrams/infrastructure-target"    (use CLUSTER_AWS/CLUSTER_VERCEL)


# ─────────────────────────────────────────────────────────
# RULES
# ─────────────────────────────────────────────────────────
# 1. ALWAYS set show=False (don't auto-open in browser)
# 2. ALWAYS set filename="docs/diagrams/infrastructure" (standard path)
# 3. ALWAYS use GRAPH_ATTR for the Diagram constructor
# 4. ALWAYS use CLUSTER_* constants for Cluster() graph_attr — pick by provider:
#    - AWS services → CLUSTER_AWS
#    - Vercel/frontend → CLUSTER_VERCEL
#    - Azure services → CLUSTER_AZURE
#    - Auth/security layers → CLUSTER_SECURITY
#    - Sub-groupings → CLUSTER_INNER
#    - Dev environment → CLUSTER_LOCAL
#    - On-premise/legacy → CLUSTER_ONPREM
# 5. ALWAYS use Edge() with color and label for non-obvious connections:
#    - Primary flow: color="#0070f3", style="bold"
#    - Auth/security: color="#d4a017", style="bold"
#    - Database: color="#7c3aed", style="bold"
#    - Internal/async: style="dashed", color="#999999"
#    - API calls: color="#666666"
# 6. ALWAYS use direction="LR" (left-to-right). Use "TB" only if >10 nodes vertical.
# 7. ALWAYS add brief labels to nodes (service name + purpose, use \n for multiline)
# 8. For migration: generate TWO scripts (infrastructure-legacy + infrastructure-target)
# 9. If Python/Graphviz not available → generate Mermaid equivalent in design.md §Infrastructure.
#    Use subgraph clusters (NOT linear flowcharts). Match the same structure.
# 10. Detect cloud provider from stacks[] in .sdd-config.json:
#     - "aws" → use diagrams.aws.*
#     - "azure" → use diagrams.azure.*
#     - mixed → use diagrams.custom.Custom for unsupported services
# 11. Include monitoring/observability nodes (CloudWatch, Datadog, etc.)
# 12. Include security nodes (auth, secrets management)
# 13. Custom icons go in docs/diagrams/icons/ (use Custom() node)
