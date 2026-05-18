# GitHub Actions Workflow Improvements

## Overview
This document outlines the improvements made to the Terraform workflows following industry best practices.

## Changes Implemented

### ✅ 1. Pinned Terraform Version (v1.9.8)
**Before:** `TF_VERSION: latest`
**After:** `TF_VERSION: 1.9.8`

**Benefits:**
- Prevents unexpected breaking changes
- Ensures consistent behavior across runs
- Makes rollbacks easier

**Maintenance:** Update version number when ready to upgrade

---

### ✅ 2. Concurrency Controls
Added to all workflows to prevent overlapping runs:

```yaml
concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: false
```

**Benefits:**
- Prevents Terraform state corruption
- Avoids race conditions
- Ensures operations complete before new ones start

**Note:** `cancel-in-progress: false` ensures running jobs complete rather than being cancelled

---

### ✅ 3. Environment Protection Gates

#### Production Environment (Apply)
- **Environment Name:** `production`
- **Protection:** Requires manual approval before apply
- **URL:** Direct link to AWS S3 Console

#### Production-Destroy Environment (Destroy)
- **Environment Name:** `production-destroy`
- **Protection:** Extra safeguard for destructive operations

**Setup Required:**
1. Go to: `Settings` → `Environments` in your GitHub repository
2. Create two environments:
   - `production`
   - `production-destroy`
3. Configure protection rules:
   - ✅ Required reviewers (add yourself or team members)
   - ✅ Wait timer (optional: 5 minutes to allow cancellation)
   - ✅ Deployment branches (optional: only from `main`)

**Benefits:**
- Prevents accidental infrastructure changes
- Provides audit trail
- Allows review before costly operations

---

### ✅ 4. Cost Estimation with Infracost

Added Infracost integration to show cost impact on PRs:

**Setup Required:**
1. Sign up at [infracost.io](https://www.infracost.io/)
2. Get API key from dashboard
3. Add to GitHub Secrets:
   - Name: `INFRACOST_API_KEY`
   - Value: Your Infracost API key

**Features:**
- Automatically comments on PRs with cost estimates
- Shows cost diff between current and proposed infrastructure
- Updates comment on each commit
- Runs only on PRs (not on direct pushes)

**Benefits:**
- Prevents budget surprises
- Shows cost impact before changes are applied
- Helps make informed decisions

---

### ✅ 5. Drift Detection Workflow

**New File:** [.github/workflows/tf-drift-detection.yml](.github/workflows/tf-drift-detection.yml)

**Schedule:** Runs daily at 9 AM UTC (or on-demand via workflow_dispatch)

**Features:**
- Detects when infrastructure diverges from Terraform state
- Creates GitHub issues automatically when drift is found
- Generates detailed reports in workflow summary
- Labels issues for easy filtering

**Benefits:**
- Catches manual changes made outside Terraform
- Maintains infrastructure as code discipline
- Provides early warning of configuration drift

**Customization:**
```yaml
schedule:
  - cron: '0 9 * * *'  # Change time/frequency as needed
```

---

### ✅ 6. Improved Region Consistency

**Environment Variables:**
- `AWS_REGION: us-east-1` (S3 backend region)
- `AWS_REPLICA_REGION: us-west-2` (S3 replication target)

**Note:** Your Terraform configuration uses:
- `primary_region: us-east-2` (in variables.tf)
- `replica_region: us-west-2`

**Recommendation:** Update [terraform/variables.tf](../../terraform/variables.tf) to match workflow regions, or update workflow regions to match Terraform.

---

## Workflow Files Updated

### [tf-create.yml](tf-create.yml) - Build Workflow
- ✅ Renamed from "VPC" to "S3 Bucket"
- ✅ Pinned Terraform version
- ✅ Added concurrency controls
- ✅ Added environment protection
- ✅ Integrated Infracost
- ✅ Fixed region variables

### [tf-destroy.yml](tf-destroy.yml) - Destroy Workflow
- ✅ Renamed from "VPC" to "S3 Bucket"
- ✅ Pinned Terraform version
- ✅ Added concurrency controls
- ✅ Added environment protection
- ✅ Fixed region variables

### [tf-drift-detection.yml](tf-drift-detection.yml) - New!
- ✅ Daily drift detection
- ✅ Automatic issue creation
- ✅ Detailed reporting

### [tfsec.yml](tfsec.yml) - Security Scanning
- ✅ Already properly configured
- ✅ No changes needed

---

## Additional Recommendations (Not Yet Implemented)

### 🔴 High Priority - Security

#### 1. OIDC Authentication (Recommended)
Replace long-lived AWS access keys with GitHub OIDC:

**Current (Less Secure):**
```yaml
aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Recommended (More Secure):**
```yaml
role-to-assume: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
```

**Setup Guide:** https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

**Benefits:**
- No credentials to rotate
- Reduced attack surface
- Automatic expiration
- Fine-grained permissions

#### 2. Pin Action Versions to SHA
**Current:** `actions/checkout@v4`
**Recommended:** `actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1`

**Benefits:**
- Prevents supply chain attacks
- Immutable references
- Can still see version via comment

#### 3. Add State Locking with DynamoDB
Your backend configuration lacks state locking:

```hcl
backend "s3" {
  bucket         = "tfstategit"
  key            = "s3-bucket-terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"  # ADD THIS
}
```

**Benefits:**
- Prevents concurrent state modifications
- Avoids state corruption
- Industry standard practice

---

## Testing Checklist

### Before Merging
- [ ] Create GitHub environments (`production`, `production-destroy`)
- [ ] Add `INFRACOST_API_KEY` secret (optional, but recommended)
- [ ] Review region consistency between Terraform and workflows
- [ ] Test drift detection workflow manually
- [ ] Verify concurrency controls work as expected

### After Merging
- [ ] Confirm manual approval gate works on apply
- [ ] Check Infracost comments appear on PRs
- [ ] Monitor first drift detection run
- [ ] Review workflow execution times

---

## Maintenance

### Regular Tasks
- **Weekly:** Review drift detection issues
- **Monthly:** Update Terraform version if new releases available
- **Quarterly:** Review and update GitHub Actions versions
- **As Needed:** Adjust drift detection schedule

### Monitoring
- Watch for failed drift detection runs
- Monitor Infracost for cost trends
- Review workflow execution times for optimization opportunities

---

## Questions or Issues?

### Common Issues

**Q: Environment not found error**
**A:** Create the environment in GitHub Settings → Environments

**Q: Infracost not commenting on PRs**
**A:** Check that `INFRACOST_API_KEY` secret is set correctly

**Q: Drift detection creating too many issues**
**A:** Adjust schedule frequency or add issue auto-close logic

**Q: Apply waiting forever**
**A:** Someone needs to approve in GitHub Actions UI (check environment protection rules)

---

## Cost Considerations

### Expected AWS Costs
- **S3 Storage:** Based on data stored
- **S3 Replication:** Based on data transferred
- **DynamoDB (if added):** ~$0.25/month for state locking
- **GitHub Actions:** Free for public repos, included minutes for private repos

### Infracost
- Free tier: Up to 1,000 resources
- Shows S3 storage costs, data transfer costs

---

## Security Notes

### Secrets Required
- `AWS_ACCESS_KEY_ID` - AWS access key (consider replacing with OIDC)
- `AWS_SECRET_ACCESS_KEY` - AWS secret key (consider replacing with OIDC)
- `INFRACOST_API_KEY` - Optional, for cost estimation

### Permissions
All workflows use minimal required permissions:
- `contents: read` - Read repository code
- `pull-requests: write` - Comment on PRs
- `id-token: write` - For OIDC (when implemented)
- `issues: write` - Create drift detection issues (drift workflow only)

---

## Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [Infracost Documentation](https://www.infracost.io/docs/)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
