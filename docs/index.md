# Requirements and Design Documentation

## Architechture Design & Planning

### Infrastructure Architecture Design

- **GitHub**
- **App Service for containers**
- **App Service Plan**
- **PostgreSQL database**
- **Static website**
- **Azure Container Registry**
- **Key Vault**
- **Log Analytics Workspace**
- **Application Insights**
- **_(TO DO: Any other service to be used (Has to be coordinated with the rest of the team))_**

### Environment Design

- **Which environments do we need for our workloads?**
  - And what configuration will our Azure services have for each environment?
- with the infra dev and the full stack dev

### Well-Architected Framework

- **Reliability**
  - with site reliability engineer
  - SLI 1: Account Availability: Ensure 95% of account access requests are successful.
  - SLI 2: Time to Access: Ensure 85% of page requests are loaded within 500ms.
  - SLI 3: Transaction Processing Time: Ensure 99% of transactions are completed within 2 seconds.

| RE:NUM | Description                                                                 | Implementation |
|--------|-----------------------------------------------------------------------------|----------------|
| RE:01  | Design your workload to align with business objectives and avoid unnecessary complexity or overhead. |                |
| RE:02  | Identify and rate user and system flows.                                    |                |
| RE:03  | Use failure mode analysis (FMA) to identify and prioritize potential failures in your solution components. |                |
| RE:04  | Define reliability and recovery targets for the components.                |                |
| RE:05  | Add redundancy at different levels, especially for critical flows.          |                |
| RE:06  | Implement a timely and reliable scaling strategy at the application, data, and infrastructure levels. |                |
| RE:07  | Strengthen the resiliency and recoverability of your workload by implementing self-preservation and self-healing measures. |                |
| RE:08  | Test for resiliency and availability scenarios by applying the principles of chaos engineering in your test and production environments. |                |
| RE:09  | Implement structured, tested, and documented business continuity and disaster recovery (BCDR) plans that align with the recovery targets. |                |
| RE:10  | Measure and model the solution's health signals.                            |                |

- **Security**
  - with cybersec engineer
  - SLI 4: Login Success Rate: Ensure 99.9% of login attempts are successful without errors due to system issues.
  - SLI 5: Fund Transfer Accuracy: Ensure 99.99% of fund transfers are accurate and error-free.

| SE:NUM | Description                                                                 | Implementation |
|--------|-----------------------------------------------------------------------------|----------------|
| SE:01  | Establish a security baseline that's aligned to compliance requirements, industry standards, and platform recommendations. |                |
| SE:02  | Maintain a secure development lifecycle.                                    |                |
| SE:03  | Classify and consistently apply sensitivity and information type labels.    |                |
| SE:04  | Create intentional segmentation and perimeters in your architecture design and in the workload's footprint on the platform. |                |
| SE:05  | Implement strict, conditional, and auditable identity and access management (IAM) across all workload users, team members, and system components. |                |
| SE:06  | Isolate, filter, and control network traffic across both ingress and egress flows. |                |
| SE:07  | Encrypt data by using modern, industry-standard methods to guard confidentiality and integrity. |                |
| SE:08  | Harden all workload components by reducing extraneous surface area and tightening configurations to increase attacker cost. |                |
| SE:09  | Protect application secrets by hardening their storage and restricting access and manipulation and by auditing those actions. |                |
| SE:10  | Implement a holistic monitoring strategy that relies on modern threat detection mechanisms that can be integrated with the platform. |                |
| SE:11  | Establish a comprehensive testing regimen.                                  |                |
| SE:12  | Define and test effective incident response procedures.                     |                |

- **Cost Optimization**
  - SKU tier optimization: we will set the SKU to 'free' for the dev enviornment to reduce cost in this low traffic environment. The UAT and Production environment SKUs will be set to 'basic', which also are more cost-effective.
  - CDN Configuration (static site): enabled in the production environment to improve performance and reduce bandwidth costs, which reduces latency for global users, and decreases data transfer costs through caching.
  - CostCenter tag (static site): this will be enabled to provide cost tracking.
  - ... add more based on other bicep files created

| CO:NUM | Description                                                                 | Implementation |
|--------|-----------------------------------------------------------------------------|----------------|
| CO:01  | Create a culture of financial responsibility.                               |                |
| CO:02  | Create and maintain a cost model. A cost model should estimate the initial cost, run rates, and ongoing costs. |                |
| CO:03  | Collect and review cost data. Data collection should capture daily costs.   |                |
| CO:04  | Set spending guardrails.                                                    |                |
| CO:05  | Get the best rates from providers.                                          |                |
| CO:06  | Align usage to billing increments.                                          |                |
| CO:07  | Optimize component costs.                                                   |                |
| CO:08  | Optimize environment costs. Align spending to prioritize preproduction, production, operations, and disaster recovery environments. |                |
| CO:09  | Optimize flow costs. Align the cost of each flow with flow priority.        |                |
| CO:10  | Optimize data costs.                                                        |                |
| CO:11  | Optimize code costs. Evaluate and modify code to meet functional and nonfunctional requirements with fewer or cheaper resources. |                |
| CO:12  | Optimize scaling costs. Evaluate alternative scaling within your scale units. |                |
| CO:13  | Optimize personnel time. Align the time personnel spends on tasks with the priority of the task. The goal is to reduce the time spent on tasks without degrading the outcome. |                |
| CO:14  | Consolidate resources and responsibility.                                    |                |

- **Operational Excellence**
  - with full stack dev
  - Collaborate to create Azure Dashboards for SLO compliance tracking and holistic observability.

| OE:NUM | Description                                                                 | Implementation |
|--------|-----------------------------------------------------------------------------|----------------|
| OE:01  | Determine workload team members' specializations and integrate them into a robust set of practices to design, develop, deploy, and operate your workload to specification. |                |
| OE:02  | Formalize the way you run routine, as needed, and emergency operational tasks by using documentation, checklists, or automation. |                |
| OE:03  | Formalize software ideation and planning processes.                         |                |
| OE:04  | Optimize software development and quality assurance processes by following industry-proven practices for development and testing. |                |
| OE:05  | Prepare resources and their configurations by using a standardized infrastructure as code (IaC) approach. |                |
| OE:06  | Build a workload supply chain that drives proposed changes through predictable, automated pipelines. |                |
| OE:07  | Design and implement a monitoring system to validate design choices and inform future design and business decisions. |                |
| OE:08  | Develop an effective emergency operations practice.                         |                |
| OE:09  | Automate all tasks that don't benefit from the insight and adaptability of human intervention, are highly procedural, and have a shelf-life that yields a return on automation investment. |                |
| OE:10  | Design and implement automation upfront for operations such as lifecycle concerns, bootstrapping, and applying governance and compliance guardrails. |                |
| OE:11  | Clearly define your workload's safe deployment practices. Emphasize the ideals of small, incremental, quality-gated release methods. |                |
| OE:12  | Implement a deployment failure mitigation strategy that addresses unexpected mid-rollout issues with rapid recovery. |                |

- **Performance Efficiency**
  - CDN (static site): enabled in the production environment to deliver static content efficiently to users, reducing latency and improving page load times for users.
  - Private endpoints (static site and database): ensures secure, low latency communication between resources
  - Application insights monitoring: Integrated for all environments to monitor application performance metrics and identify bottlenecks, allowing for proactive optimization.
  - ... to be continued
  - Conduct load testing for SLI 2: Page Load Time and SLI 3: Transaction Processing Time.
  - Optimize scalability of infrastructure to handle peak loads while maintaining performance thresholds.

| PE:NUM | Description                                                                 | Implementation |
|--------|-----------------------------------------------------------------------------|----------------|
| PE:01  | Define performance targets.                                                 |                |
| PE:02  | Conduct capacity planning.                                                  |                |
| PE:03  | Select the right services. The services, infrastructure, and tier selections must support your ability to reach the workload's performance targets and accommodate expected capacity changes. |                |
| PE:04  | Collect performance data.                                                   |                |
| PE:05  | Optimize scaling and partitioning.                                          |                |
| PE:06  | Test performance. Perform regular testing in an environment that matches the production environment. |                |
| PE:07  | Optimize code and infrastructure.                                           |                |
| PE:08  | Optimize data usage.                                                        |                |
| PE:09  | Prioritize the performance of critical flows.                               |                |
| PE:10  | Optimize operational tasks.                                                 |                |
| PE:11  | Respond to live performance issues.                                         |                |
| PE:12  | Continuously optimize performance.                                          |                |

## Software Design & Planning

### Release Strategy

### CI/CD Pipeline and Release Strategy

### Use Cases and Sequential Model Diagrams
Must include for each use case

### Entity Relationship Diagram for the Database

### 12 Factor App Design

1. **Codebase**  
   One codebase tracked in revision control, many deploys

2. **Dependencies**  
   Explicitly declare and isolate dependencies

3. **Config**  
   Store config in the environment

4. **Backing services**  
   Treat backing services as attached resources

5. **Build, release, run**  
   Strictly separate build and run stages

6. **Processes**  
   Execute the app as one or more stateless processes

7. **Port binding**  
   Export services via port binding

8. **Concurrency**  
   Scale out via the process model

9. **Disposability**  
   Maximize robustness with fast startup and graceful shutdown

10. **Dev/prod parity**  
    Keep development, staging, and production as similar as possible

11. **Logs**  
    Treat logs as event streams

12. **Admin processes**  
    Run admin/management tasks as one-off processes


### Documented User Stories
