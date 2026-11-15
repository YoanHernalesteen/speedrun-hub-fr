class EventPolicy < ApplicationPolicy
  # Events are public: anyone can browse them, nobody can change them through the API.
  def index?
    true
  end

  def show?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
