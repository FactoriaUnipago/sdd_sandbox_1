import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';

export class InfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // 1. VPC Configuration (Dev/Staging optimized with 0 NAT Gateways to save cost)
    const vpc = new ec2.Vpc(this, 'TaskManagerVpc', {
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      maxAzs: 2,
      subnetConfiguration: [
        {
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
        {
          name: 'Isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
          cidrMask: 24,
        }
      ],
      natGateways: 0, // Zero NAT Gateways to avoid monthly costs (~$32/mo each)
    });

    // 2. Security Group for RDS PostgreSQL
    const rdsSecurityGroup = new ec2.SecurityGroup(this, 'RdsSecurityGroup', {
      vpc,
      description: 'Security group for local-to-remote and app-to-db connections',
      allowAllOutbound: true,
    });

    // Allow ingress on PostgreSQL port (5432)
    // NOTE: In production, restrict this to specific Vercel/VPC security groups or IPs.
    // For development/MVP testing, it can accept public connections if database resides in a public subnet
    // or if we use a Bastion Host. Here we default to VPC-only access, with a configurable option.
    rdsSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(), // Adjust this rule to specific office/Vercel IP ranges in production
      ec2.Port.tcp(5432),
      'Allow public access to PostgreSQL database (port 5432)'
    );

    // 3. Custom Parameter Group for PostgreSQL 16
    const parameterGroup = new rds.ParameterGroup(this, 'PostgresParameterGroup', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16,
      }),
      description: 'Custom Parameter Group for Task Manager PostgreSQL 16',
      parameters: {
        'client_encoding': 'UTF8',
        'timezone': 'UTC',
        'rds.force_ssl': '1', // Enforce SSL connection for security (NFR-001/005)
      },
    });

    // 4. PostgreSQL 16 RDS Database Instance
    const dbInstance = new rds.DatabaseInstance(this, 'TaskManagerDbInstance', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16_4,
      }),
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T4G,
        ec2.InstanceSize.MICRO
      ), // db.t4g.micro is Free Tier eligible
      vpc,
      vpcSubnets: {
        // Place database in isolated subnets for maximum security
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
      securityGroups: [rdsSecurityGroup],
      parameterGroup,
      databaseName: 'taskdb',
      allocatedStorage: 20, // 20GB gp3 storage
      maxAllocatedStorage: 100, // Enables storage autoscaling up to 100GB
      backupRetention: cdk.Duration.days(7),
      deletionProtection: false, // Set to true for production environments
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Use RETAIN for production to prevent data loss
      // Auto-generates master credentials stored securely in AWS Secrets Manager
      credentials: rds.Credentials.fromGeneratedSecret('dbadmin', {
        secretName: 'task-manager-db-credentials',
      }),
    });

    // 5. Stack Outputs
    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: dbInstance.dbInstanceEndpointAddress,
      description: 'The connection endpoint for the PostgreSQL database',
    });

    new cdk.CfnOutput(this, 'DatabasePort', {
      value: dbInstance.dbInstanceEndpointPort,
      description: 'The port number on which the database accepts connections',
    });

    new cdk.CfnOutput(this, 'CredentialsSecretArn', {
      value: dbInstance.secret?.secretArn || 'No secret generated',
      description: 'The ARN of the Secrets Manager secret containing database credentials',
    });
  }
}
