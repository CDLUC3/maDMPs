require_relative 'helpers'
require_relative 'marker'
require_relative 'project_identifier'
require_relative 'project_type'

class Project
  def initialize(hash)
    @id = params[:id]
    @source_id = params[:source_id]
    @source_json = prepare_json(params[:source_json])
    @title = params[:title]
    @identifiers = ProjectIdentifier.find_all(
      conn, { source_id: @source_id, project_id: @id }
    )
  end

  # -----------------------------------------------------------
  def self.find(conn, hash)
    if conn.respond_to?(:query)
      if !hash[:id].nil?
        sql = "SELECT * FROM projects WHERE id = #{hash[:id]};"
      elsif !hash[:identifiers].nil?
        sql = "SELECT * FROM projects WHERE id IN (\
                SELECT project_id FROM project_identifiers \
                WHERE identifier IN ('#{hash[:identifiers].join(', ')}')\
              )"
      else # Search by title
        sql = "SELECT * FROM projects \
               WHERE title = '#{hash[:title]}' \
               AND source_id = #{hash[:source_id]}"
      end
      object_from_hash(self.class, conn.query(sql).first.to_h)
    else
      nil
    end
  end

  # -----------------------------------------------------------
  def self.create!(conn, hash)
    if conn.respond_to?(:query)
      if valid?(hash)
        stmt = conn.prepare("INSERT INTO projects \
                                (title, description, source_id, source_json) \
                              VALUES (?, ?, ?, ?)")
        id = stmt.execute(hash[:title], hash[:description], hash[:source_id], hash.to_s)
        project_id = conn.last_id

        # Create any identifiers
        unless hash[:identifiers].nil?
          hash[:identifiers].each do |identifier|
            identifier_hash = {
              source_id: hash[:source_id],
              project_id: project_id,
              identifier: identifier
            }
            ProjectIdentifier.create!(conn, identifier_hash) if ProjectIdentifier.find(conn, identifier_hash).nil?
          end
        end
        
        # Create any types
        unless hash[:identifiers].nil?
          hash[:types].each do |type|
            type_hash = {
              source_id: hash[:source_id],
              project_id: project_id,
              type: type
            }
            ProjectType.create!(conn, type_hash) if ProjectType.find(conn, type_hash).nil?
          end
        end
        
        # Create any markers
        unless hash[:markers].nil?
          hash[:markers].each do |marker|
            Marker.create!(conn, {
              project_id: project_id,
              source_id: hash[:source_id],
              source_json: marker.to_json
            }.merge(marker))
          end
        end
        
        project_id
      else
        nil
      end
    else
      nil
    end
  end

  # -----------------------------------------------------------
  def id
    @id
  end
  def title
    @title
  end
  def title=(val)
    @title = val
  end
  def identifiers
    @identifiers
  end
  def identifiers=(array)
    @identifiers = array || []
  end
  def markers
    @markers
  end
  def markers=(array)
    @markers = array || []
  end
  def expeditions
    @expeditions
  end
  def expeditions=(array)
    @expeditions = array || []
  end

private
  def self.valid?(hash)
    !hash[:title].nil? && !hash[:source_id].nil?
  end
end

=begin
    {
      "identifiers": [
        "https://www.bco-dmo.org/project/2218",
        "OA-Copepod_PreyQual"
      ],
      "types": [
        "CreativeWork",
        "http://ocean-data.org/schema/Project"
      ],
      "title": "Impacts on copepod populations mediated by changes in prey quality",
      "description": "Research shows that ocean acidification (OA) has physiological consequences for individual organisms, even those lacking calcium carbonate skeletal structures. However, this existing research does not adequately address how OA effects to individuals are linked across trophic levels. Pelagic copepods are critical players in most marine biogeochemical cycles. Their consumption of phytoplankton and microzooplankton is the primary mechanism by which bacterial and phytoplankton production is transferred to higher trophic levels. Despite their high abundance and ecological importance, copepods have received little research attention concerning OA. The few extant studies focused on direct acute effects to copepods (e.g. egg hatching, survival) under elevated pCO2, and few significant effects have been observed at predicted future pCO2. However, there is increasing recognition that OA significantly affects their phytoplankton prey, including elevating growth rates, increasing cell sizes, altering nutrient uptake and ratios, and chemical composition. Because copepod grazing, egg production, and hatching success all can vary with these prey characteristics, OA mediated changes in phytoplankton quality may be an important indirect mechanism through which OA acts on copepod populations and, ultimately, marine food webs. This study that will advance our understanding of how copepod populations may be affected by OA, specifically through OA induced changes in phytoplankton quality. Our core objective is to determine how changes in phytoplankton physiology and biochemistry (e.g. lipid composition) affect copepod egg production, hatching, and ontogenetic development of nauplii. We will also include a subset of experiments to test whether OA affects copepod reproductive output independent of changes to prey. To achieve these research goals, the diatom, Ditylum brightwellii , and dinoflagellate, Prorocentrum micans , will be cultured semi-continuously under several pCO2 concentrations, during which time we will characterize changes in their physiology and biochemistry. The copepods, Calanus pacificus , a large, high lipid-bearing marine species, and Acartia clausi , a smaller, low lipid-bearing estuarine species, will be maintained across varying pCO2 concentrations and fed these pCO2-acclimated prey, and their grazing and reproductive capability quantified. The copepods and phytoplankton used in this study will be collected from the Salish Sea, a region already experiencing periods of high pCO2/H+ (>1000 ppm, pH 7.5) on varying timescales. Therefore, this research addresses a question of how future climate change may impact marine ecosystems, but also is relevant to pCO2/H+ variability presently experienced in coastal environments.",
      "contributors": [
        {
          "name": "Dr Brady  M. Olson",
          "identifiers": [
            "http://lod.bco-dmo.org/id/person/51528"
          ],
          "role": "Principal Investigator",
          "org": {
            "name": "Western Washington University - Shannon Point Marine Center"
          }
        },
        {
          "name": "Dr Julie E. Keister",
          "identifiers": [
            "http://lod.bco-dmo.org/id/person/51330"
          ],
          "role": "Co-Principal Investigator",
          "org": {
            "name": "University of Washington"
          }
        },
        {
          "name": "Dr Brooke Love",
          "identifiers": [
            "http://lod.bco-dmo.org/id/person/51527"
          ],
          "role": "Co-Principal Investigator",
          "org": {
            "name": "Western Washington University"
          }
        }
      ],
      "awards": [
        {
          "org": {
            "types": [
              "Organization"
            ],
            "identifiers": [
              "http://lod.bco-dmo.org/id/funding/355"
            ],
            "name": "NSF Division of Ocean Sciences (NSF OCE)"
          },
          "name": "OCE-1220664",
          "identifiers": [
            "http://lod.bco-dmo.org/id/award/54980",
            "OCE-1220664",
            "http://www.nsf.gov/awardsearch/showAward.do?AwardNumber=1220664"
          ],
          "offered_by": {
            "name": "Dr David  L. Garrison",
            "identifiers": [
              "http://lod.bco-dmo.org/id/person/50534"
            ],
            "role": "http://ocean-data.org/schema/ProgramManagerRole"
          }
        },
        {
          "org": {
            "types": [
              "Organization"
            ],
            "identifiers": [
              "http://lod.bco-dmo.org/id/funding/355"
            ],
            "name": "NSF Division of Ocean Sciences (NSF OCE)"
          },
          "name": "OCE-1220381",
          "identifiers": [
            "http://lod.bco-dmo.org/id/award/55093",
            "OCE-1220381",
            "http://www.nsf.gov/awardsearch/showAward.do?AwardNumber=1220381"
          ],
          "offered_by": {
            "name": "Dr David  L. Garrison",
            "identifiers": [
              "http://lod.bco-dmo.org/id/person/50534"
            ],
            "role": "http://ocean-data.org/schema/ProgramManagerRole"
          }
        }
      ],
      "documents": [
        {
          "types": [
            "application/pdf"
          ],
          "description": "Data Management Plan",
          "uri": "https://www.bco-dmo.org/project/2218/plan/1333"
        }
      ]
    }
=end

