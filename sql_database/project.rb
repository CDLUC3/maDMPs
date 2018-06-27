require_relative 'helpers'
require_relative 'marker'
require_relative 'project_identifier'

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
                                (title, source_id, source_json) \
                              VALUES (?, ?, ?)")
        id = stmt.execute(hash[:title], hash[:source_id], hash[:source_json])
        project_id = conn.last_id

        # Create any identifiers
        hash[:identifiers].each do |identifier|
          ProjectIdentifier.create!(conn, {
            source_id: hash[:source_id],
            project_id: project_id,
            identifier: identifier
          })
        end

        # Create any markers
        hash[:markers].each do |marker|
          Marker.create!(conn, {
            project_id: project_id,
            source_id: hash[:source_id],
            source_json: marker.to_json
          }.merge(marker))
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
