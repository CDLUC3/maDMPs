# maDMPs

## Services

There are several services defined in the database which have corresponding subfolders in this project. Each services either downloads data via an API or loads it via a file manually placed in the service's `/tmp` directory. The service then transforms that data into a standardized JSON format.

### Berkeley Biocode

The Berkeley Biocode site currently houses the GUMP Moorea research station project metadata: http://bnhmipt.berkeley.edu/ipt/resource?r=biocode. This information will be moving to the GeOMe project. The EML file must be manually downloaded and placed into the `biocode/tmp/biocode.xml` directory

### GeOMe

The [Genomic Observatories Metadatabase](https://www.geome-db.org/) (GeOMe) contains project, and dataset metadata. The service retrieves data directly from GeOMe via their public API.

This program was based on the [R program](https://github.com/DIPnet/fimsR-access) referenced on the GeOMe website. The underlying code makes HTTPS calls to the [FIMS API](https://fims.readthedocs.io/en/latest/fims/introduction.html) to query the GeOMe database and retrieve JSON data.

### BCO-DMO

The BCO-DMO project metadata must be acquired manually and placed into the `bco_dmo/tmp/bco_dmo.json` directory. 

### NSF 

This service scans through the database and queries the NSF API for award metadata.

### DMPTool

This service scans through the database and queries the DMPTool for DMP metadata.

## Standardized JSON Output

All of the services produce a standard JSON output:
```json
{
  "projects": [
    {
      "identifiers": ["99999", "ABCD"],
      "types": ["Creative Work", "http://url.to.my/controlled/vocabulary/page"],
      "title": "Sample Project",
      "description": "This is a description of our important project",
      "license": "MIT",
      "publication_date": "2018-01-01",
      "language": "en",

      "markers": [
        {
          "uri": "",
          "value": "MS-A",
          "defined_by": "",
          "definition": "mitochondrial sub-unit A"
        },
        {
          "uri": "http://controlled.vocab.org/test",
          "value": "ABC",
          "defined_by": "creator name",
          "definition": "species ABC"
        }
      ],

      "contributors": [
        {
          "name": "John Doe",
          "email": "john.doe@nowhere.org",
          "role": "Principal Investigator",
          "org": {
            "types": ["Institution"],
            "identifiers": ["UONW"],
            "name": "University of Nowhere"
          }
        }
      ],

      "awards": [
        {
          "name": "ABCD-1234 Semi-Annual for exceptional research topics",
          "identifiers": ["ABCD-1234", "http://url.to.my/awards/landing/page"],
          "org": {
            "types": ["Organization"],
            "identifiers": ["http://link.to.an/org/page"],
            "name": "Funder Institution"
          },
          "offered_by": {
            "name": "Dr. Funder Person",
            "identifiers": ["http://link.to.an/user/landing/page"],
            "role": "Program Manager"
          }
        }
      ],

      "documents": [
        {
          "identifiers": ["https://dmptool.org/path/to/dmp.pdf"],
          "types": ["Data Management Plan", "application/pdf"],
          "title": "Data Management Plan"
        }
      ],
      
      "stages": [
        {
          "identifiers": ["12389", "TEST 1"],
          "types": ["Cruise"],
          "title": "TEST 1 spreadsheet dataset",
          "start_date": "2018-06-21 08:09:10",
          "contributors": [
            {
              "identifiers": ["0"],
              "name": "demo",
              "role": "Co-principal Investigator"
            }
          ],
          "public": "true"
        }
      ]
    }
  ],
}
```

## SQL Database

There is a MySQL database definition in `sql_database/maDMPs.sql` which can be used to generate your DB. Once your DB has been created you can run `ruby application.rb` to populate it. 

- To run all services and load their findings into the DB run `ruby application.rb`.
- To run a specific service(s) and load its findings into the DB just supply the name(s) of the services you want to run: `ruby application service1 service2`

The available services are: biocode, geome, bco_dmo, nsf, dmptool
