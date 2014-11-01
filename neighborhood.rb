class Neighborhood < ActiveRecord::Base
  scope :with_point, ->(x,y) { where("poly @> point(?,?)",x,y) }

  def poly
    ps = read_attribute :poly
    eval ps.gsub("(","[").gsub(")","]")
  end

  def poly=(array)
    data = array.to_s.gsub("[","(").gsub("]",")")
    write_attribute :poly,data
  end

end
