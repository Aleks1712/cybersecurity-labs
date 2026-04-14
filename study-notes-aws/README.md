# ☁️ AWS Solutions Architect Associate (SAA-C03)

![AWS](https://img.shields.io/badge/AWS-SAA--C03-FF9900?style=flat-square&logo=amazonaws)
![Status](https://img.shields.io/badge/Status-In_Progress-yellow?style=flat-square)
![Sections](https://img.shields.io/badge/Sections-11-green?style=flat-square)

Study notes for the AWS Solutions Architect Associate exam. Based on the Adrian Cantrill SAA-C03 course, AWS documentation, and hands-on experience from the AWS Community GameDay Europe 2026.

**Exam:** SAA-C03 | 65 questions | 130 minutes | 720/1000 to pass | $150 USD

## 📋 Sections

| # | Topic | Highlights |
|:-:|-------|-----------|
| [01](section-01-intro-and-accounts/) | AWS Accounts & Exam Overview | Account structure, root user, multi-account strategy `mermaid` |
| [02](section-02-cloud-fundamentals/) | Cloud Fundamentals | Regions, AZs, edge locations, global infrastructure `mermaid` |
| [03](section-03-iam/) | IAM | Users, groups, roles, policies, federation `mermaid` `cli` |
| [04](section-04-vpc/) | VPC & Networking | Subnets, route tables, NACLs, security groups, NAT `mermaid` `cli` |
| [05](section-05-s3/) | S3 | Storage classes, versioning, encryption, lifecycle policies `cli` |
| [06](section-06-ec2/) | EC2 | Instance types, AMIs, EBS, placement groups, user data `cli` |
| [07](section-07-ha-and-scaling/) | HA & Scaling | ELB, ASG, multi-AZ, Route 53 `mermaid` |
| [08](section-08-databases/) | Databases | RDS, Aurora, DynamoDB, ElastiCache, Redshift |
| [09](section-09-serverless/) | Serverless | Lambda, API Gateway, SQS, SNS, Step Functions `mermaid` |
| [10](section-10-security/) | Security | KMS, CloudTrail, GuardDuty, WAF, Shield `cli` `gameday` |
| [🐳](aws-containers-wiz-ctf/) | Containers with Wiz & O3C CTF | Docker layers, K8s security, CNAPP, attack paths `mermaid` `cli` |

> `mermaid` = diagram · `cli` = AWS CLI code · `gameday` = from AWS Community GameDay 2026

## 🗺️ Exam Domains

| Domain | Weight |
|--------|--------|
| Design Secure Architectures | 30% |
| Design Resilient Architectures | 26% |
| Design High-Performing Architectures | 24% |
| Design Cost-Optimized Architectures | 20% |

## 🐾 Course Scenario: Animals4Life

The Cantrill course uses a fictional organization called Animals4Life throughout all labs:

- Small on-premises datacenter in Brisbane, Australia (192.168.10.0/24)
- Badly implemented AWS pilot in Sydney region (10.0.0.0/16)
- A few isolated Azure/GCP pilots (172.31.0.0/16)
- Global offices in London, New York, Seattle
- Field workers worldwide using laptops, IoT devices, 3G/4G connections
- Large research datasets that need to be available around the clock
- Cost-conscious but progressive management team

**Current problems:** Legacy hardware failing, messy cloud pilots, performance issues for field workers, no HA or scalability, limited automation, expensive global expansion.

**How AWS solves this:** Pay-as-you-go eliminates CapEx, global regions reduce latency, auto-scaling handles variable demand, managed services reduce staffing, IaC enables automation.

---

[⬅️ Back to Study Notes](../)
