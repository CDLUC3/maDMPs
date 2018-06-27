class ExpeditionIdentifier
  def initialize(hash)
    @source_id = params[:source_id]
    @expedition_id = params[:expedition_id]
    @identifier = params[:identifier]
  end

  # -------------------------------------------------
  def self.find_all(conn, hash)
    ret = []
    if !hash[:expedition_id].nil? && !hash[:source_id].nil?
      recs = conn.query("SELECT * \
                         FROM expedition_identifiers \
                         WHERE source_id = #{hash[:source_id]} \
                         AND expedition_id = #{hash[:expedition_id]}")
      recs.each do |rec|
        ret << object_from_hash(self.class, rec)
      end
    end
    ret
  end

  # -------------------------------------------------
  def self.find(conn, hash)
    if hash[:expedition_id].nil?
      sql = "SELECT * \
             FROM expedition_identifiers \
             WHERE source_id = #{hash[:source_id]} \
             AND expedition_id = '#{hash[:identifier]}'"
    else
      sql = "SELECT * \
             FROM expedition_identifiers \
             WHERE source_id = #{hash[:source_id]} \
             AND expedition_id = #{hash[:expedition_id]} \
             AND identifier = '#{hash[:identifier]}'"
    end
    object_from_hash(self.class, conn.query(sql).first)
  end

  # -------------------------------------------------
  def self.create!(conn, hash)
    if conn.respond_to?(:query) && valid?(hash)
      stmt = conn.prepare("INSERT INTO expedition_identifiers \
                            (source_id, expedition_id, identifier) \
                           VALUES (?, ?, ?)")
      stmt.execute(hash[:source_id], hash[:expedition_id], hash[:identifier])
      find(conn, hash)
    else
      nil
    end
  end

  # -------------------------------------------------
  def id
    @id
  end
  def expedition_id
    @expedition_id
  end
  def source_id
    @source_id
  end

private
  def self.valid?(hash)
    !hash[:expedition_id].nil? && !hash[:source_id].nil? &&
    !hash[:identifier].nil? && hash[:identifier] != ''
  end
end
