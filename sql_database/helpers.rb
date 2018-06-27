
def object_from_hash(clazz, hash)
  if clazz.respond_to?(:initialize)
    obj = clazz.new
    obj.initialize(hash)
  end
end

# -----------------------------------------------------------
def prepare_json(json, exclusion_list)
  json.select{ |k,v| !exclusion_list.include?(k) }.to_json
end

# -----------------------------------------------------------
def collect_identifiers(json, identifiers_list)
  json.select{ |k,v| identifiers_list.include?(k.to_sym) }.values
end
