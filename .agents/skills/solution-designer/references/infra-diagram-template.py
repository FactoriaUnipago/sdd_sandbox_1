# Infrastructure Diagram Template — Reference (Python `diagrams` library)
# pip install diagrams
# Requires: Graphviz installed (https://graphviz.org/download/)

# ─────────────────────────────────────────────────────────
# STYLING STANDARD — Use these for ALL infrastructure diagrams
# Aligned with proven sandbox_1 output
# ─────────────────────────────────────────────────────────

GRAPH_ATTR = {
    "bgcolor": "#ffffff",
    "pad": "2.0",
    "fontsize": "16",
    "fontname": "Sans-Serif",
    "fontcolor": "#1a1a2e",
    "splines": "ortho",
    "nodesep": "0.80",
    "ranksep": "0.90",
    "dpi": "600",
}

NODE_ATTR = {
    "fontname": "Sans-Serif",
    "fontsize": "12",
    "fontcolor": "#2D3436",
}

# Cluster styles — pick by provider/purpose
CLUSTER_VERCEL = {
    "bgcolor": "#f0f7ff",
    "style": "rounded",
    "pencolor": "#0070f3",
    "penwidth": "2.0",
    "fontname": "Sans-Serif",
    "fontsize": "14",
    "fontcolor": "#0050b3",
}

CLUSTER_AWS = {
    "bgcolor": "#fff8f0",
    "style": "rounded",
    "pencolor": "#ff9900",
    "penwidth": "2.0",
    "fontname": "Sans-Serif",
    "fontsize": "14",
    "fontcolor": "#cc7a00",
}

CLUSTER_AZURE = {
    "bgcolor": "#f0f4ff",
    "style": "rounded",
    "pencolor": "#0078d4",
    "penwidth": "2.0",
    "fontname": "Sans-Serif",
    "fontsize": "14",
    "fontcolor": "#005a9e",
}

CLUSTER_SECURITY = {
    "bgcolor": "#fffbf0",
    "style": "rounded",
    "pencolor": "#d4a017",
    "penwidth": "1.5",
    "fontname": "Sans-Serif",
    "fontsize": "12",
    "fontcolor": "#8a6d00",
}

CLUSTER_INNER = {
    "bgcolor": "#ffffff",
    "style": "rounded",
    "pencolor": "#d0d7de",
    "penwidth": "1.5",
    "fontname": "Sans-Serif",
    "fontsize": "11",
    "fontcolor": "#57606a",
}

CLUSTER_LOCAL = {
    "bgcolor": "#f0fff4",
    "style": "rounded",
    "pencolor": "#2da44e",
    "penwidth": "2.0",
    "fontname": "Sans-Serif",
    "fontsize": "14",
    "fontcolor": "#1a7f37",
}

CLUSTER_ONPREM = {
    "bgcolor": "#f5f5f5",
    "style": "rounded",
    "pencolor": "#666666",
    "penwidth": "2.0",
    "fontname": "Sans-Serif",
    "fontsize": "14",
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
# EXAMPLE 1: Vercel + AWS Hybrid (Production)
# ─────────────────────────────────────────────────────────
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.database import RDS
from diagrams.aws.security import IAM
from diagrams.aws.management import Cloudwatch
from diagrams.onprem.client import Users
from diagrams.programming.framework import React
from diagrams.programming.language import NodeJS
from diagrams.onprem.security import Vault
from diagrams.generic.network import Firewall
from diagrams.saas.cdn import Cloudflare

with Diagram(
    "",
    filename="docs/diagrams/infrastructure",
    show=False,
    direction="LR",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
):
    users = Users("Clients")

    with Cluster("VERCEL PLATFORM", graph_attr=CLUSTER_VERCEL):
        with Cluster("Edge CDN", graph_attr=CLUSTER_INNER):
            cdn = Cloudflare("SSL/TLS\nGlobal CDN")

        with Cluster("Frontend SPA", graph_attr=CLUSTER_INNER):
            spa = React("React 18\nVite + TypeScript")

        with Cluster("Security Layer", graph_attr=CLUSTER_SECURITY):
            api_gate = Firewall("API Key Gate\nx-api-key header")
            jwt = Vault("JWT Verify\nToken → userId")

        with Cluster("Business Logic", graph_attr=CLUSTER_INNER):
            api = NodeJS("Express 5\nControllers + Prisma")

    with Cluster("AWS  ·  us-east-1", graph_attr=CLUSTER_AWS):
        with Cluster("VPC  ·  Private Subnet", graph_attr=CLUSTER_INNER):
            db = RDS("PostgreSQL 16\ndb.t3.micro · 20GB")

        iam = IAM("IAM Role\nDB Credentials")
        monitoring = Cloudwatch("CloudWatch\nAlarms + Logs")

    # Client → Vercel
    users >> Edge(color="#0070f3", style="bold", label="HTTPS") >> cdn
    cdn >> Edge(color="#0070f3") >> spa

    # Frontend → Security → API
    spa >> Edge(color="#666666", label="fetch /api/*") >> api_gate
    api_gate >> Edge(color="#d4a017", style="bold", label="✓ valid key") >> jwt
    jwt >> Edge(color="#d4a017", style="bold", label="✓ userId") >> api

    # API → AWS
    api >> Edge(color="#7c3aed", style="bold", label="Prisma ORM\nTCP :5432") >> db

    # AWS internal
    iam >> Edge(style="dashed", color="#999999", label="rotate\ncredentials") >> db
    db >> Edge(style="dashed", color="#999999", label="metrics") >> monitoring


# ─────────────────────────────────────────────────────────
# EXAMPLE 2: Development Environment
# Generate BOTH production + dev diagrams for every project
# ─────────────────────────────────────────────────────────
from diagrams.onprem.container import Docker

with Diagram(
    "",
    filename="docs/diagrams/infrastructure-dev",
    show=False,
    direction="LR",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
):
    dev = Users("Developer")

    with Cluster("LOCAL  ·  localhost", graph_attr=CLUSTER_LOCAL):
        with Cluster("Frontend  :3000", graph_attr=CLUSTER_INNER):
            vite = React("Vite Dev Server\nHMR + Proxy")

        with Cluster("API  :4000", graph_attr=CLUSTER_INNER):
            express = NodeJS("Express 5\nnodemon + ts-node")

        with Cluster("Docker  :5432", graph_attr=CLUSTER_INNER):
            pg = Docker("postgres:16-alpine\nVolume persistente")

    dev >> Edge(color="#2da44e", style="bold", label="http://localhost:3000") >> vite
    vite >> Edge(color="#666666", label="proxy /api → :4000") >> express
    express >> Edge(color="#7c3aed", style="bold", label="DATABASE_URL") >> pg


# ─────────────────────────────────────────────────────────
# EXAMPLE 3: AWS Full Stack (Serverless)
# ─────────────────────────────────────────────────────────
# from diagrams.aws.network import CloudFront, APIGateway, Route53
# from diagrams.aws.compute import Lambda
# from diagrams.aws.integration import SQS, SNS
# from diagrams.aws.security import Cognito, SecretsManager
# from diagrams.aws.storage import S3
#
# with Diagram("", filename="docs/diagrams/infrastructure", show=False,
#              direction="LR", graph_attr=GRAPH_ATTR, node_attr=NODE_ATTR):
#     dns = Route53("payments.example.com")
#     with Cluster("AWS — us-east-1", graph_attr=CLUSTER_AWS):
#         cdn = CloudFront("CDN")
#         with Cluster("API Layer", graph_attr=CLUSTER_INNER):
#             apigw = APIGateway("REST API\n/api/v1/*")
#             authorizer = Lambda("Authorizer\nJWT validation")
#         with Cluster("Business Logic", graph_attr=CLUSTER_INNER):
#             fn = Lambda("Payments\nCRUD + Stripe")
#         with Cluster("Data", graph_attr=CLUSTER_INNER):
#             db = RDS("PostgreSQL 16\ndb.t3.medium")
#     dns >> Edge(color="#0070f3", style="bold", label="HTTPS") >> cdn >> apigw
#     apigw >> Edge(color="#d4a017", style="bold", label="✓ JWT") >> authorizer
#     apigw >> Edge(color="#666666") >> fn
#     fn >> Edge(color="#7c3aed", style="bold", label="TCP :5432") >> db


# ─────────────────────────────────────────────────────────
# EXAMPLE 4: Migration (legacy vs target)
# ─────────────────────────────────────────────────────────
# Generate TWO diagrams for migration projects:
#   filename="docs/diagrams/infrastructure-legacy"   (use CLUSTER_ONPREM)
#   filename="docs/diagrams/infrastructure-target"    (use CLUSTER_AWS/CLUSTER_VERCEL)


# ─────────────────────────────────────────────────────────
# RULES
# ─────────────────────────────────────────────────────────
# 1. ALWAYS set show=False (don't auto-open in browser)
# 2. ALWAYS set filename="docs/diagrams/infrastructure" (standard path)
# 3. ALWAYS use GRAPH_ATTR + NODE_ATTR for the Diagram constructor
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
# 8. ALWAYS generate TWO diagrams: production + development (infrastructure + infrastructure-dev)
# 9. For migration: generate TWO EXTRA scripts (infrastructure-legacy + infrastructure-target)
# 10. If Python/Graphviz not available → generate Mermaid equivalent in design.md §Infrastructure.
#     Use subgraph clusters (NOT linear flowcharts). Match the same structure.
# 11. Detect cloud provider from stacks[] in .sdd-config.json:
#     - "aws" → use diagrams.aws.*
#     - "azure" → use diagrams.azure.*
#     - mixed → use diagrams.custom.Custom for unsupported services
# 12. Include monitoring/observability nodes (CloudWatch, Datadog, etc.)
# 13. Include security nodes (auth, secrets management)
# 14. Custom icons go in docs/diagrams/icons/ (use Custom() node)
# 15. Font: ALWAYS Sans-Serif (portable). NEVER Helvetica Neue (not available everywhere)
# 16. DPI: 600 for high quality output (standard default).
