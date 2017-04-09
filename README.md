# Scraper para Talento

En el lugar donde trabajo, tienen que estar contactando a mucha gente para ver si va y hace entrevista. Para esto, usan la página de OCC para juntar CVs. Para que no tengan que tener a una (o varias) personas dedicadas a estarle picando a la página con el simple propósito de recopilar mails y datos de contacto, les hice este scraper.

## Instalación
Clona el repo y corre Bundler

```bash
git clone git@github.com:jaimerodas/scraper_talento.git
cd scraper_talento
bundle install
```

## Configuración
Hay que crear un archivo `config.yml` tal como viene el `config_sample.yml` pero con los atributos correctos.

## Ejecución

Gracias a que ya tenemos un bonito ejecutable:

```bash
bin/scraper_talento
```

## Resultado
Cuando termine de correr el script (y se puede tardar un bueeen rato), va a guardar un archivo en el directorio del proyecto que se llama `resultados.csv`. Espero que guarde los datos que querías.
