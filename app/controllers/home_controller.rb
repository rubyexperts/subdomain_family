class HomeController < ApplicationController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:legal_policy, :terms]
  before_filter :selected_tab
  layout 'default', :exclude => [:admin, :legal_policy, :terms]
 
  def index
    if current_user.is_admin?
      redirect_to "/admin"
    elsif current_user.is_doctor?
      redirect_to "/doctors"
    elsif current_user.is_patient?
      redirect_to "/patients"
    elsif current_user.is_staff? || current_user.is_nurse? 
      redirect_to "/staff"
    elsif current_user.is_company?
      redirect_to "/company"
    elsif current_user.is_account_user?
      redirect_to "/accounts"
    end
  end
  
  def admin
    @select = "home"
    render :layout => 'admin'
  end
  
  def staff
  end
  
  def company
  end
  
  def legal_policy
    render :layout => 'login'
  end
  
  def terms
    render :layout => 'login'
  end
  
  private
  
  def selected_tab
    @select =  "home"
  end
   

end
