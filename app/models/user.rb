class User < ActiveRecord::Base
  acts_as_authentic
  has_many :tracks
  after_create { User.refresh_rank }
  
  def refresh_stats
    cx = Classifications.count :joins => [:tracks => :users], 
                               :conditions => "value != nil AND user_id = #{self.id}"    
    self.meters_explored = cx * APP_CONFIG[:meters_per_cell]
    save
    User.refresh_rank
  end
  
  #NICE. PG 8.4 RANK
  def self.refresh_rank
    User.connection.update "UPDATE users SET rank = u2.rank FROM (SELECT id, meters_explored, rank() OVER(ORDER BY meters_explored DESC) FROM users) as u2 WHERE users.id = u2.id"
  end
  
  def game_json current_user
    {:id => self.id,
     :username => self.username,
     :avatar => "http://www.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.new.update(email)}",
     :rank => self.rank,
     :meters_explored => self.meters_explored,
     :current_user => self == current_user ? true : false}    
  end
end
