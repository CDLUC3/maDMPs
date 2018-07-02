# maDMPs

## GeOMe Reader

The geome_reader directory contains a simple Ruby utility program that queries the [Genomic Observatories Metadatabase](https://www.geome-db.org/) for project, expedition, and marker metadata.

To run the program (assuming you have cloned this project to your local machine): `ruby geome_reader/application.rb` 

This program was based on the [R program](https://github.com/DIPnet/fimsR-access) referenced on the GeOMe website. The underlying code makes HTTPS calls to the [FIMS API](https://fims.readthedocs.io/en/latest/fims/introduction.html) to query the GeOMe database and retrieve JSON data.

JSON output:
```json
{
  "projects": [
    {
      "identifiers": ["99999", "ABCD"],
      "types": ["Creative Work", "http://url.to.my/controlled/vocabulary/page"],
      "title": "Sample Project",
      "description": "This is a description of our important project",
      
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
          "role": "Principal Investigator"
        }
      ],
      
      "awards": [{
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
      }]
      
      "expeditions": [
        {
          "identifiers": ["12389", "TEST 1"], 
          "title": "TEST 1 spreadsheet dataset", 
          "start_date": "2018-06-21 08:09:10",
          "user": {
            "identifiers": ["0"], 
            "name": "demo", 
            "role": "Co-principal Investigator"
          }, 
          "public": "true"
        }
      ]
    }
  ],
}
```
