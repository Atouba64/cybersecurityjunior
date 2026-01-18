---
layout: post
title: "AWS IAM Engineer Analysis & Compliance Toolkit"
date: 2026-01-17 15:15:00 -0500
categories: [AWS, IAM, Security, Automation]
tags: [aws, iam, security-analysis, compliance, python, boto3, cis-benchmark, nist, security-automation, iam-audit, access-management]
image: https://placehold.co/1000x400/6C757D/FFFFFF?text=AWS+IAM+Engineer+Analysis+Toolkit
excerpt: "A complete IAM analysis toolkit that automatically audits AWS IAM configurations, checks compliance against CIS and NIST standards, and generates detailed security reports—perfect for learning enterprise IAM security practices."
---

# AWS IAM Engineer Analysis & Compliance Toolkit

### Business Value & Impact

Okay, so here's the deal—IAM security is like the foundation of cloud security, but honestly? Most people don't know where to start. This toolkit changes that. **My contribution** includes building the complete analysis engine from scratch, implementing compliance checking against industry standards, and creating a testing framework that actually helps you learn.

**Key Business Metrics:**
- **100% automated IAM auditing** across all users, roles, and policies
- **Compliance validation** against CIS AWS Foundations, NIST 800-53, and AWS Best Practices
- **Comprehensive reporting** in HTML, JSON, and CSV formats
- **Zero manual audit time** needed—everything runs automatically
- **Diverse test scenarios** covering real-world security issues

### Risk Reduction

This project teaches you how to:
- **Detect security misconfigurations** like missing MFA, old access keys, and overprivileged users
- **Identify compliance violations** before they become audit findings
- **Find unused credentials** that could be exploited if compromised
- **Catch inline policies** that should be managed policies
- **Spot excessive permissions** that violate least-privilege principles

### Reporting & Visibility

The toolkit generates beautiful, actionable reports showing:
- Security findings with severity levels (critical, high, medium, low)
- Compliance check results against industry standards
- Detailed user, role, and group analysis
- Recommendations for fixing each finding
- Exportable data for further analysis

### Technical Contributions

I built this to be **actually useful**, not just a demo:
- **Complete IAM analyzer** that checks users, roles, groups, and policies
- **Compliance checker** validating against CIS, NIST, and AWS best practices
- **Report generator** creating HTML, JSON, and CSV outputs
- **Testing framework** with diverse scenarios for learning
- **Demo script** so you can test without AWS credentials
- **Comprehensive docs** so you actually know how to use it

---

## What This Project is About

Think of this as your **IAM security Swiss Army knife**. You know how frustrating it is to manually check if users have MFA enabled, or figure out which access keys are too old? This toolkit does all of that automatically.

Here's what makes it special:

**🔍 Complete IAM Analysis**
- Scans all IAM users, roles, groups, and policies
- Checks for security misconfigurations
- Identifies unused credentials
- Detects excessive permissions

**✅ Compliance Checking**
- Validates against CIS AWS Foundations Benchmark
- Checks NIST 800-53 compliance
- Enforces AWS security best practices
- Generates compliance reports

**📊 Detailed Reporting**
- HTML reports with visual findings
- JSON data for programmatic access
- CSV exports for spreadsheet analysis
- Clear recommendations for each issue

**🧪 Built for Learning**
- Test scenarios covering real security issues
- Demo mode that works without AWS
- Step-by-step testing guides
- Customizable compliance rules

## What You'll Learn

This project is perfect if you're trying to:
- **Break into cloud security** and need real hands-on IAM experience
- **Level up your AWS skills** beyond basic console clicking
- **Understand compliance** requirements like CIS and NIST
- **Build automation tools** that security teams actually use
- **Prepare for interviews** with actual working code

### Skills You'll Master

By building and testing this project, you'll get hands-on experience with:

**IAM Deep Dive**
- How to analyze IAM users, roles, and policies programmatically
- Understanding MFA requirements and access key rotation
- Detecting inline policies vs. managed policies
- Finding unused credentials and orphaned resources

**Compliance Frameworks**
- CIS AWS Foundations Benchmark implementation
- NIST 800-53 security controls
- AWS security best practices
- Automated compliance reporting

**Python & Boto3**
- Using AWS SDK to interact with IAM
- Handling pagination for large account audits
- Error handling and retry logic
- Building production-ready scripts

**Security Analysis**
- Identifying security misconfigurations
- Risk assessment and severity classification
- Creating actionable security reports
- Automating security audits

---

## Step-by-Step Testing Guide

Ready to test this thing? Here's exactly what you need to do, step by step. No fluff, just actionable steps.

### Prerequisites (Get These First)

Before you start testing, make sure you have:

1. **Python 3.8+ installed**
   ```bash
   python3 --version
   # Should show Python 3.8 or higher
   ```

2. **Git installed** (to clone the repo)

3. **AWS Account** (optional for full testing, but demo mode works without it)

4. **AWS CLI configured** (only if you want to test with real AWS)
   ```bash
   aws configure
   ```

### Step 1: Clone the Repository

First things first—get the code on your machine:

```bash
git clone https://github.com/Atouba64/aResume.git
cd aResume/AWS_IAM_Engineer
```

### Step 2: Install Dependencies

Set up your Python environment and install what you need:

```bash
# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

This installs all the Python packages you need:
- `boto3` for AWS API calls
- `pyyaml` for configuration files
- `pytest` for running tests
- Other dependencies for reporting

### Step 3: Explore the Project Structure

Get familiar with what you're working with:

```bash
# See what's in the project
ls -la

# Check out the configuration
cat config/config.yaml

# Look at test data
cat data/test_data/sample_iam_data.json
```

### Step 4: Run the Demo (No AWS Required!)

Perfect for first-time testing. This shows you how everything works without needing AWS credentials:

```bash
python scripts/demo_test.py
```

**What this does:**
- Shows you the project structure
- Displays test data scenarios
- Explains compliance rules
- Demonstrates the analysis workflow
- No AWS credentials needed!

### Step 5: Run Unit Tests

Test that everything is working correctly:

```bash
# Install pytest if needed
pip install pytest pytest-cov

# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_iam_analyzer.py -v
```

**Expected results:**
- All tests should pass
- You'll see test coverage information
- Any failures will show what needs fixing

### Step 6: Test with Sample Data

The project includes 6 different test scenarios. Check them out:

```bash
# View test scenarios in a readable format
cat data/test_data/sample_iam_data.json | python3 -m json.tool
```

**Test scenarios included:**
1. **Standard User with MFA** - Well-configured user (should pass most checks)
2. **User without MFA** - Security risk (should trigger MFA finding)
3. **User with Old Access Key** - Key older than 90 days (should be flagged)
4. **User with Inline Policies** - Should use managed policies
5. **Service Role** - Properly configured EC2 role
6. **Overprivileged Role** - Excessive permissions detection

### Step 7: Test with Real AWS (Optional)

If you have AWS credentials configured, you can test against a real account:

```bash
# Verify AWS connection
aws sts get-caller-identity

# Run basic analysis
python scripts/run_analysis.py

# Run with compliance checks
python scripts/run_analysis.py --compliance

# Generate all report formats
python scripts/run_analysis.py --compliance --output-format json html csv
```

**⚠️ Important:** Make sure your AWS credentials have the necessary IAM read permissions (see `docs/SETUP.md` for details).

### Step 8: Review Generated Reports

Check out the reports that were generated:

```bash
# List generated reports
ls -la data/reports/

# View HTML report (open in browser)
open data/reports/iam_analysis_*.html

# View JSON report
cat data/reports/iam_analysis_*.json | python3 -m json.tool

# View CSV report
cat data/reports/iam_analysis_*.csv
```

**Report formats:**
- **HTML**: Beautiful visual report with findings and recommendations
- **JSON**: Machine-readable data for further processing
- **CSV**: Spreadsheet-compatible for Excel/Google Sheets

---

## Customizing Your Tests

Want to make this your own? Here's how to customize everything:

### Customize Compliance Rules

Edit `config/compliance_rules.yaml` to add your own rules:

```yaml
rules:
  - id: CUSTOM-1.1
    name: "Custom rule: Ensure all users have tags"
    severity: medium
    description: "All users must have at least one tag"
    check: user_tags_exist
    threshold: true
```

### Adjust Analysis Settings

Modify `config/config.yaml` to change analysis behavior:

```yaml
analysis:
  max_key_age_days: 60  # Change from 90 to 60 days
  check_unused_credentials: true
  detect_excessive_permissions: true
```

### Add New Test Scenarios

Add your own test cases to `data/test_data/sample_iam_data.json`:

```json
{
  "test_scenarios": {
    "scenario_7": {
      "name": "Your Custom Scenario",
      "description": "Test a specific security issue",
      "user": {
        "username": "test_user_7",
        "mfa_enabled": false,
        "access_keys": []
      }
    }
  }
}
```

### Create Custom Reports

Modify `src/report_generator.py` to add your own report formats or customize the HTML template.

### Add New Compliance Checks

Extend `src/compliance_checker.py` to add checks for your organization's specific requirements.

---

## Testing Checklist

Use this checklist to make sure you've tested everything:

- [ ] Project structure verified (all files present)
- [ ] Dependencies installed successfully
- [ ] Demo script runs without errors
- [ ] Unit tests all pass
- [ ] Test data scenarios reviewed
- [ ] Configuration files validated
- [ ] Reports generated successfully (HTML, JSON, CSV)
- [ ] (Optional) Real AWS analysis completed
- [ ] Compliance checks working
- [ ] Custom rules tested

---

## What to Test First

If you're short on time, here's the **minimum testing flow**:

1. **Run the demo** (2 minutes)
   ```bash
   python scripts/demo_test.py
   ```

2. **Check test data** (5 minutes)
   ```bash
   cat data/test_data/sample_iam_data.json | python3 -m json.tool
   ```

3. **Run unit tests** (2 minutes)
   ```bash
   pytest tests/ -v
   ```

4. **Review a sample report** (5 minutes)
   - Look at the HTML report structure
   - Check what findings look like

Total time: ~15 minutes to get a feel for the project!

---

## Technologies You'll Master

By working with this project, you'll get hands-on experience with:

- **Python 3.8+**: Modern Python with type hints and best practices
- **Boto3**: AWS SDK for Python to interact with IAM APIs
- **YAML**: Configuration file format for rules and settings
- **Pytest**: Python testing framework for unit tests
- **IAM Concepts**: Users, roles, policies, groups, and trust relationships
- **Compliance Frameworks**: CIS, NIST, and AWS security best practices
- **Report Generation**: Creating HTML, JSON, and CSV outputs

---

## Real-World Application

After testing and understanding this project, you'll be able to:

- ✅ Interview confidently for AWS IAM Engineer or Cloud Security roles
- ✅ Discuss IAM security challenges and solutions
- ✅ Explain compliance requirements like CIS and NIST
- ✅ Build your own IAM analysis tools
- ✅ Demonstrate practical Python and Boto3 skills
- ✅ Show understanding of security automation

---

## GitHub Repository

🔗 **Complete source code and documentation:** [github.com/Atouba64/aResume/tree/main/AWS_IAM_Engineer](https://github.com/Atouba64/aResume/tree/main/AWS_IAM_Engineer)

The repository includes everything you need:
- Complete Python source code with detailed comments
- Configuration files for compliance rules
- Comprehensive test suite
- Step-by-step testing guides
- Demo script for learning
- Sample test data with diverse scenarios
- Complete documentation (SETUP, TESTING, API_REFERENCE)

---

## Additional Learning Resources

Want to dive deeper? Check out:

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) - Official AWS guide
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services) - Compliance standard
- [NIST 800-53 Security Controls](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final) - Security framework
- [Boto3 IAM Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam.html) - AWS SDK reference

---

## Final Thoughts

Look, I know IAM security can feel overwhelming. There's a lot to learn, and it's easy to get lost in all the documentation. But here's the thing—this toolkit gives you a **real, working example** of how to actually do IAM analysis and compliance checking.

You're not just reading about it or watching videos. You're running code, seeing results, and understanding how it all fits together. That's the kind of experience that sticks with you.

So clone the repo, run the tests, play around with the code, and customize it for your needs. That's how you actually learn this stuff—by doing it.

**Ready to start testing?** [Check out the GitHub repository](https://github.com/Atouba64/aResume/tree/main/AWS_IAM_Engineer) and run the demo script. It's literally 2 minutes to see it in action.

---
