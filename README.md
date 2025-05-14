# Open WebUI Helm Charts (Technologymatch Fork)

<!-- BEGIN TECHNOLOGYMATCH CHANGES -->
This is a fork of the [Open WebUI](https://github.com/open-webui/open-webui) Helm charts repository, customized for Technologymatch deployments.

## Technologymatch Customizations

All Technologymatch-specific customizations are contained in the `/technologymatch` directory to keep our changes clearly separated from the upstream project. This includes:

- Terraform infrastructure for AWS deployment
- Documentation for custom code deployment
- Environment-specific configurations

See the [/technologymatch/README.md](/technologymatch/README.md) file for details on our customizations.

## Original Repository
<!-- END TECHNOLOGYMATCH CHANGES -->

The original README content from the Open WebUI Helm Charts project follows:

---

# Open WebUI Helm Charts
Helm charts for the [Open WebUI](https://github.com/open-webui/open-webui) application.

## Downloading the Chart
The charts are hosted at https://helm.openwebui.com. You can add the Helm repo with:
```
helm repo add open-webui https://helm.openwebui.com/
```