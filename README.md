# SOF-SSL
Acquire and deploy SSL cerificates on [Heroku](https://www.heroku.com/home) using free certificates from [Lets Encrypt](https://letsencrypt.org/).

For Heroku deployments using paid dynos, please see https://devcenter.heroku.com/articles/automated-certificate-management.

## Prerequisites
In order to use this script you must fulfill the following requirements:
- The Heroku CLI is installed and authenticated with your account
- Either [sof-webapp](https://github.com/studentorkesterfestivalen/sof-webapp) or [sof-dbapp](https://github.com/studentorkesterfestivalen/sof-dbapp) deployed on Heroku
- A configured or unconfigured SSL extension on Heroku (added in application settings). This can be done by executing `heroku addons:create ssl:endpoint`
- A domain pointing to your Heroku app

## Usage
Run the script with Ruby as following:
```bash
ruby acquire.rb [DOMAIN] [APP NAME] (--create)
```
Replace `[DOMAIN]` with the domain for which you wish to acquire a cerificate and replace `[APP NAME]` with your app identifier on Heroku.

The `--create` flag must be used on apps which has no previously configured certificate. Do not use this flag for already configured apps.

**NOTE:** The command parsing is very dumb and you MUST order the arguments in the same order as above or the script will fail!

### Example usage
```bash
ruby acquire.rb www.sof17.se sof-web-production
```
