# Managing Your Open WebUI Fork

This document explains how to manage your fork of the Open WebUI Helm charts repository, including making custom changes while still being able to incorporate upstream updates.

## Fork Workflow Overview

As a fork of the original Open WebUI Helm charts repository, you'll need to balance:
1. Custom changes specific to your deployment needs
2. Incorporating updates from the upstream repository

## Setting Up Remote References

First, ensure your repository is properly configured with both your fork and the upstream repository:

```bash
# Check current remotes
git remote -v

# If upstream is not configured, add it
git remote add upstream https://github.com/open-webui/open-webui-helm-charts.git

# Verify remotes
git remote -v
```

This gives you:
- `origin`: Your fork (technologymatch/open-webui-helm-charts)
- `upstream`: The original repository (open-webui/open-webui-helm-charts)

## Making Custom Changes

When you need to customize the Helm charts:

1. Create a feature branch for your changes:
   ```bash
   git checkout -b feature/my-custom-feature
   ```

2. Make your changes to the necessary files. Common customizations include:
   - Modifying values in `charts/open-webui/values.yaml`
   - Adding company-specific templates in `charts/open-webui/templates/`
   - Creating custom environments in `terraform/environments/`

3. Commit your changes with clear messages:
   ```bash
   git add .
   git commit -m "Add custom feature X for Technologymatch deployment"
   ```

4. Push your changes to your fork:
   ```bash
   git push origin feature/my-custom-feature
   ```

5. Create a pull request in your fork to merge to your main branch.

## Getting Updates from Upstream

To incorporate the latest changes from the Open WebUI team:

1. Fetch the latest changes from upstream:
   ```bash
   git fetch upstream
   ```

2. Create an integration branch from your main branch:
   ```bash
   git checkout main
   git checkout -b upstream-integration
   ```

3. Merge the upstream changes:
   ```bash
   git merge upstream/main
   ```

4. Resolve any merge conflicts:
   - Files will be marked with conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Edit the files to resolve conflicts
   - For conflicts in your custom code, carefully preserve your customizations
   - For conflicts in the Helm chart values, compare carefully and merge appropriately
   - Use `git add <file>` to mark conflicts as resolved

5. Test the merged code:
   - Validate the Helm charts: `helm lint charts/open-webui`
   - Test the chart with a dry run: `helm template charts/open-webui`

6. Commit the merged changes:
   ```bash
   git commit -m "Merge latest changes from upstream"
   ```

7. Create a pull request from your `upstream-integration` branch to your `main` branch.

## Maintaining a Clean Fork

To keep your fork manageable over time:

1. **Document Custom Changes**: Keep a log of custom modifications you've made in a `CUSTOMIZATIONS.md` file.

2. **Use Git Tags**: Tag your stable versions after testing:
   ```bash
   git tag -a v6.13.0-tm1 -m "TechnologyMatch custom version based on 6.13.0"
   git push origin v6.13.0-tm1
   ```

3. **Minimize Invasive Changes**: When possible, make changes that don't modify the core structure:
   - Prefer overriding values in your custom values.yaml file
   - Use Terraform to manage infrastructure without changing chart internals
   - Take advantage of the Helm templating features

## Advanced: Cherry-Picking Specific Updates

If you only want specific updates from upstream:

1. Identify the commit(s) you want:
   ```bash
   git log upstream/main
   ```

2. Cherry-pick the specific commit:
   ```bash
   git cherry-pick <commit-hash>
   ```

## Handling Major Upstream Changes

When the upstream repository makes significant changes:

1. **Create a Comparison Branch**:
   ```bash
   git checkout -b upstream-compare upstream/main
   ```

2. **Compare with Your Version**:
   ```bash
   git diff main..upstream-compare -- charts/open-webui/templates/
   ```

3. **Consider a Clean Start**:
   For very major changes, it might be easier to:
   - Save your custom code separately
   - Pull the latest upstream version
   - Re-apply your customizations carefully

## Testing After Merging Upstream Changes

Always test thoroughly after integrating upstream changes:

1. **Lint the Charts**:
   ```bash
   helm lint charts/open-webui
   ```

2. **Template Rendering**:
   ```bash
   helm template open-webui charts/open-webui -f terraform/environments/dev/values.yaml
   ```

3. **Sandbox Deployment**:
   Set up a separate namespace for testing the merged charts before deploying to development.
   ```bash
   kubectl create namespace open-webui-test
   helm install open-webui-test charts/open-webui -n open-webui-test -f test-values.yaml
   ```

## Releasing Your Fork

After successfully merging upstream changes and your customizations:

1. Update your Terraform environment configuration to use the new version.

2. Tag your release:
   ```bash
   git tag -a v6.13.0-tm2 -m "TechnologyMatch release with upstream changes plus XYZ improvements"
   git push origin v6.13.0-tm2
   ```

3. Update your documentation to reflect the changes.