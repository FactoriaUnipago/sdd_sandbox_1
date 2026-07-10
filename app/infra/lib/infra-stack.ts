import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';

interface EnvironmentConfig {
  vpcId: string;
  dbInstanceType: string;
  allocatedStorage: number;
  maxAllocatedStorage: number;
  backupRetentionDays: number;
  deletionProtection: boolean;
  removalPolicy: 'DESTROY' | 'RETAIN';
  allowedCidrs: string[];  // CIDR ranges allowed to connect to RDS
}

export class InfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // 1. Resolve environment configuration from context (defaulting to 'dev')
    const targetEnv = this.node.tryGetContext('env') || 'dev';
    const envs = this.node.tryGetContext('environments');
    
    if (!envs || !envs[targetEnv]) {
      throw new Error(`Environment "${targetEnv}" is not defined in cdk.json context.`);
    }

    const config: EnvironmentConfig = envs[targetEnv];

    // 2. VPC Configuration (Lookup existing VPC or create a new one)
    let vpc: ec2.IVpc;
    if (config.vpcId) {
      console.log(`[CDK] Importing existing VPC: ${config.vpcId}`);
      vpc = ec2.Vpc.fromLookup(this, 'TaskManagerVpc', {
        vpcId: config.vpcId,
      });
    } else {
      console.log(`[CDK] Creating a new VPC for environment: ${targetEnv}`);
      vpc = new ec2.Vpc(this, 'TaskManagerVpc', {
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
        natGateways: 0, // Dev/Staging optimized to avoid monthly NAT costs
      });
    }

    // 3. Security Group for RDS PostgreSQL
    const rdsSecurityGroup = new ec2.SecurityGroup(this, 'RdsSecurityGroup', {
      vpc,
      description: `Security group for Task Manager RDS PostgreSQL (${targetEnv})`,
      allowAllOutbound: true,
    });

    // Add ingress rules for each allowed CIDR
    config.allowedCidrs.forEach((cidr, index) => {
      rdsSecurityGroup.addIngressRule(
        ec2.Peer.ipv4(cidr),
        ec2.Port.tcp(5432),
        `Allow PostgreSQL access from CIDR ${index + 1} for ${targetEnv}`
      );
    });

    // 4. Custom Parameter Group for PostgreSQL 16
    const parameterGroup = new rds.ParameterGroup(this, 'PostgresParameterGroup', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16,
      }),
      description: `Custom Parameter Group for Task Manager PostgreSQL 16 (${targetEnv})`,
      parameters: {
        'client_encoding': 'UTF8',
        'timezone': 'UTC',
        'rds.force_ssl': '1', // Enforce SSL connection (NFR-001/005)
      },
    });

    // Determine removal policy enum
    const removalPolicy = config.removalPolicy === 'RETAIN' 
      ? cdk.RemovalPolicy.RETAIN 
      : cdk.RemovalPolicy.DESTROY;

    // 5. PostgreSQL 16 RDS Database Instance
    const dbInstance = new rds.DatabaseInstance(this, 'TaskManagerDbInstance', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16_4,
      }),
      instanceType: new ec2.InstanceType(config.dbInstanceType),
      vpc,
      vpcSubnets: {
        // Place in isolated subnets for maximum safety
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
      securityGroups: [rdsSecurityGroup],
      parameterGroup,
      databaseName: 'taskdb',
      allocatedStorage: config.allocatedStorage,
      maxAllocatedStorage: config.maxAllocatedStorage,
      backupRetention: cdk.Duration.days(config.backupRetentionDays),
      deletionProtection: config.deletionProtection,
      removalPolicy,
      // Auto-generates master credentials stored securely in AWS Secrets Manager (unique per environment)
      credentials: rds.Credentials.fromGeneratedSecret('dbadmin', {
        secretName: `task-manager-db-credentials-${targetEnv}`,
      }),
    });

    // 6. Stack Outputs
    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: dbInstance.dbInstanceEndpointAddress,
      description: `The connection endpoint for the PostgreSQL database (${targetEnv})`,
    });

    new cdk.CfnOutput(this, 'DatabasePort', {
      value: dbInstance.dbInstanceEndpointPort,
      description: 'The port number on which the database accepts connections',
    });

    new cdk.CfnOutput(this, 'CredentialsSecretArn', {
      value: dbInstance.secret?.secretArn || 'No secret generated',
      description: `The ARN of the Secrets Manager secret containing database credentials (${targetEnv})`,
    });
  }
}
