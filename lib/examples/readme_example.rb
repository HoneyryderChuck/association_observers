# -*- encoding : utf-8 -*-
# Logger
require 'logger'

LOGGER = Logger.new(STDOUT)

# Notifiers
class HaveSliceNotifier < Notifier::Base

  def action(cake, kid)
    cake.update_column(:slices, cake.slices - 1)
    cake.destroy if cake.slices == 0
    kid.increment(:slices).save
  end

end

class BustKidsAssNotifier < Notifier::Base

  module ObserverMethods
    def bust_kids_ass!
      LOGGER.info("Slam!!")
    end
  end

  module ObservableMethods
    def is_for_grandpa?
      true # it is always for grandpa
    end
  end

  def conditions(cake, mom)
    cake.is_for_grandpa?
  end

  def action(cake, mom)
    mom.bust_kids_ass!
  end

end

class TellKidHesFatNotifier < Notifier::Base

  module ObservableMethods
    def cry!
      LOGGER.info(":'(")
    end

    def throw_slices_away!
      update_column(:slices, 0)
    end
  end

  def conditions(kid, mom)
    kid.slices > 20
  end

  def action(kid, mom)
    LOGGER.info("Hey Fatty, BEEFCAKE!!!!!")
    kid.cry!
    kid.throw_slices_away!
  end

end


# TABLES

ActiveRecord::Schema.define do
  create_table :cakes, :force => true do |t|
    t.integer :slices
    t.integer :mom_id
  end
  create_table :kids, :force => true do |t|
    t.integer :mom_id
    t.integer :slices, :default => 0
  end
  create_table :moms, :force => true do |t|
  end
end

# ENTITIES

class Cake < ActiveRecord::Base

  def self.default_slices ; 8 ; end
  belongs_to :mom
  has_one :kid, :through => :mom
  before_create do |record|
    record.slices ||= record.class.default_slices
  end
end

class Mom < ActiveRecord::Base
  has_one :kid
  has_many :cakes
end

class Kid < ActiveRecord::Base
  belongs_to :mom
  has_many :cakes, :through => :mom

  observes :cakes, :notifier => :have_slice, :on => :create
end

class Mom < ActiveRecord::Base
  observes :cakes, :on => :destroy, :notifier => :bust_kids_ass
  observes :kid, :on => :update, :notifier => :tell_kid_hes_fat
end





