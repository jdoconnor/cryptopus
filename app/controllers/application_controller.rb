# $Id$

# Copyright (c) 2007 Puzzle ITC GmbH. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_filter :validate, :except => [:login, :authenticate, :logout]
  before_filter :prepare_menu
  before_filter :set_locale


protected

  def validate
    unless session[:user_id]
      session[:jumpto] = request.parameters
      redirect_to login_login_path
      return
    end

    # remember the URL before loging out or recrypt
    unless params[:controller] == "recryptrequests"
      session[:jumpto] = request.parameters
    end

    user = User.find( session[:user_id] )
    
    if Recryptrequest.find(:first, :conditions => ["user_id = ?" , user.id])
      flash[:notice] = t('flashes.application.wait')
      redirect_to :controller => 'login', :action => 'logout'
      return
    end
    
  end
  
  def set_locale
    user_locale = session[:user_id] ? User.find( session[:user_id] ).preferred_locale : I18n.default_locale
    # use the locale parameter if provided or else the user locale
    I18n.locale = params[:locale] || user_locale
  end
  
  def get_team_password
    user = User.find(session[:user_id] )
    teammember = @team.teammembers.find( :first, :conditions => ["user_id = ?", user.id] )
    raise "You have no access to this Group" if teammember.nil?
    team_password = CryptUtils.decrypt_team_password( teammember.password, session[:private_key] )
    raise "Failed to decrypt the group password" if team_password.nil?
    return team_password
  end
  
  def is_user_team_member( team_id, user_id )
    team_member = Teammember.find( :first, :conditions => ["team_id=? and user_id=?", team_id, user_id] )
    return true if team_member
    return false
  end
  
  def am_i_team_member( team_id )
    user = User.find( session[:user_id] )
    return is_user_team_member( team_id, user.id )
  end

  def prepare_menu
    if File.exist?("#{Rails.root}/app/views/#{controller_path}/_#{action_name}_menu.html.erb")  
      @menu_to_render = "#{controller_path}/#{action_name}_menu"
    else
      @menu_to_render = nil
    end
  end

end
