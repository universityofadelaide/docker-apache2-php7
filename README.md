# University of Adelaide Apache2 PHP7 Docker Image

A customised Apache2 PHP7 Docker image, designed for use on the Shepherd Docker
hosting platform.

## Usage

When running, volume your project into the `/code` directory:

```
docker run --detach --publish 80:80 --volumes ${PWD}:/code uofa/apache2-php7
```

## Details

* This image expects your code to be volumed or copied into the `/code`
directory.
* Apache serves `/code/web` as the webroot.
* The `$WEB_PATH` environment variable can be used to set the sub-path your
web root is served from. This should start with a slash - e.g. `/test/path`.

## To build manually.

```bash
docker build -t uofa/apache2-php7 .
```
