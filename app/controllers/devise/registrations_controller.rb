class Devise::RegistrationsController < ApplicationController

  prepend_before_filter :require_no_authentication, :only => [ :new, :create, :cancel ]
  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy]
  include Devise::Controllers::InternalHelpers  

  # GET /resource/sign_up
  def new
    @select = "sign_up"
    session[:user_params] ||= {}
    session[:site_params] ||= {}
    @user = User.new(session[:user_params])
    @site = Site.new(session[:site_params])  
    @user.current_step = session[:user_basic] 
  end
  
  def create
    session[:user_params].deep_merge!(params[:user]) if params[:user]
    session[:site_params].deep_merge!(params[:site]) if params[:site]
    @user = User.new(session[:user_params])
    @site = Site.new(session[:site_params])
    @user.current_step = session[:user_basic]
    @sub_domain = params[:site][:name] if params[:site]
    if @user.valid?
      if params[:previous_button]
        @user.get_previous_step("Doctor")
        @sub_domain = params[:site][:name] if params[:site]
        @occupation = params[:user_detail][:occupation] if params[:user_detail]
      elsif @user.last_step?
        if @user.valid? && @site.valid?
          @site.save
          @user.type = "Doctor"
          @user.is_owner = true
          @user.site = @site
          @user.save
        end
      else
        @user.get_next_step("Doctor")
        @sub_domain = params[:site][:name] if params[:site]
        @occupation = params[:user_detail][:occupation] if params[:user_detail]
      end
      session[:user_basic] = @user.current_step
    end
    if @user.new_record?
      render 'new', :layout => 'login'
    else
      session[:user_basic] = session[:user_params] = nil
      flash[:notice] = "You have signed up successfully. If enabled, a confirmation was sent to your e-mail."
      redirect_to("http://#{@site.name}.#{request.host}:3000")
    end
  end

  # GET /resource/edit
  def edit
    render_with_scope :edit
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    if resource.update_with_password(params[resource_name])
      set_flash_message :notice, :updated if is_navigational_format?
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource){ render_with_scope :edit }
    end
  end

  # DELETE /resource
  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_navigational_format?
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    expire_session_data_after_sign_in!
    redirect_to new_registration_path(resource_name)
  end

  protected

    # Build a devise resource passing in the session. Useful to move
    # temporary session data to the newly created user.
    def build_resource(hash=nil)
      hash ||= params[resource_name] || {}
      self.resource = resource_class.new_with_session(hash, session)
    end

    # The path used after sign up. You need to overwrite this method
    # in your own RegistrationsController.
    def after_sign_up_path_for(resource)
      after_sign_in_path_for(resource)
    end

    # Overwrite redirect_for_sign_in so it takes uses after_sign_up_path_for.
    def redirect_location(scope, resource)
      stored_location_for(scope) || after_sign_up_path_for(resource)
    end

    # Returns the inactive reason translated.
    def inactive_reason(resource)
      reason = resource.inactive_message.to_s
      I18n.t("devise.registrations.reasons.#{reason}", :default => reason)
    end

    # The path used after sign up for inactive accounts. You need to overwrite
    # this method in your own RegistrationsController.
    def after_inactive_sign_up_path_for(resource)
      root_path
    end

    # The default url to be used after updating a resource. You need to overwrite
    # this method in your own RegistrationsController.
    def after_update_path_for(resource)
      if defined?(super)
        ActiveSupport::Deprecation.warn "Defining after_update_path_for in ApplicationController " <<
          "is deprecated. Please add a RegistrationsController to your application and define it there."
        super
      else
        after_sign_in_path_for(resource)
      end
    end

    # Authenticates the current scope and gets the current resource from the session.
    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", true)
      self.resource = send(:"current_#{resource_name}")
    end
    

    
end
