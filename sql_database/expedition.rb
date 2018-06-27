require_relative 'expedition_identifier'
require_relative 'project_expedition'

class Expedition
  def initialize(hash)
    @source_id = params[:source_id]
    @title = params['title']
    @start_date = params['start_date']
    @public = params['public']
    @source_json = params[:source_json]
  end

  # -----------------------------------------------------------
  def self.find(conn, hash)
    if conn.respond_to?(:query) && valid?(hash)
      if !hash[:id].nil?
        sql = "SELECT * FROM expeditions WHERE id = #{hash[:id]};"
      elsif !hash[:identifiers].nil?
        sql = "SELECT * FROM expeditions WHERE id IN (\
                SELECT expedition_id FROM expedition_identifiers \
                WHERE identifier IN ('#{hash[:identifiers].join(', ')}')\
              )"
      else # Search by title
        sql = "SELECT * FROM expeditions \
               WHERE title = '#{hash[:title]}' \
               AND source_id = #{hash[:source_id]}"
      end

puts sql
      object_from_hash(self.class, conn.query(sql).first.to_h)
    else
      nil
    end
  end

  # -------------------------------------------------
  def self.create!(conn, hash)
    if conn.respond_to?(:query) && valid?(hash)
      stmt = conn.prepare(
        "INSERT INTO expeditions \
          (source_id, source_json, title, start_date, public) \
        VALUES (?, ?, ?, ?, ?)")
      stmt.execute(hash[:source_id], hash[:source_json], hash[:title],
                   hash[:ts], hash[:public])
      expedition_id = conn.last_id

      # Create any identifiers
      hash[:identifiers].each do |identifier|
        ExpeditionIdentifier.create!(conn, {
          source_id: hash[:source_id],
          expedition_id: expedition_id,
          identifier: identifier
        })
      end

      # Create link between project and expedition
      unless hash[:project_id].nil?
        ProjectExpedition.create!(conn, {
          source_id: hash[:source_id],
          project_id: hash[:project_id],
          expedition_id: expedition_id
        })
      end
      
      expedition_id
    else
      nil
    end
  end

  # -------------------------------------------------
  def id
    @id
  end
  def title
    @title
  end
  def start_date
    @start_date
  end
  def public?
    @public
  end

private
  def self.valid?(hash)
    !hash[:title].nil? && !hash[:source_id].nil?
  end
end
