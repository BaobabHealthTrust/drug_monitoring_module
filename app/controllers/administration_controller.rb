class AdministrationController < ApplicationController
  def index
  end
  def add_site
    @nojquery = true
  end
  def list_sites
    sites = YAML.load_file("#{Rails.root}/config/sites.yml")
    @sites = {}
    (sites || []).each do |name, value|
       @sites[name] = {"address" => value.split(":")[0],"port" => value.split(":")[1]}  unless value.blank?
    end
  end
  def edit_site
    @sites = Site.all
    @nojquery = true
  end

  def delete_site
    settings = YAML.load_file("#{Rails.root}/config/sites.yml")
    settings.delete params[:site]
    File.open("#{Rails.root}/config/sites.yml",'w'){|f| YAML.dump(settings, f)}
    render :text => "Site details removed"
  end

  def save_site

    unless params.blank? || !request.post?
      if params[:old_site].blank?

        site = Site.create({:name => params[:sitename], :x => params[:x],
                            :y => params[:y], :region => params[:region],
                            :ip_address => params[:ip_address], :port => params[:port]})

      elsif
        site = Site.find(:first, :conditions => ["name = ? ", params[:old_site]])
        site.name = params[:sitename]
        site.x = params[:x]
        site.y = params[:y]
        site.region = params[:region]
        site.ip_address = params[:ip_address]
        site.port = params[:port]
        site.threshold = params[:threshold]
        site.save
      end
    end
    redirect_to "/"
  end

  def map
    @region = params["region"] rescue nil
    @label = nil

    @region = "blank" if @region.blank?

    case @region.to_s.downcase
      when "centre"
        @label = "Central Region"
      when "north"
        @label = "Northern Region"
      when "south"
        @label = "Southern Region"
    end

    @x = nil
    @y = nil

    if !params["x"].blank?
      @x = params["x"]
    end

    if !params["y"].blank?
      @y = params["y"]
    end

    render :layout => false
  end

  def save_notice_changes
    to_be_resolved = params[:to_be_resolved].split(',')
    to_be_investigated = params[:to_be_investigated].split(',')

    unless (to_be_resolved.blank?)
      to_be_resolved.each do |obs_id|
        obs_state = State.find_by_observation_id(obs_id)
        obs_state.state = 'Resolved'
        obs_state.save!
      end
    end

    unless (to_be_investigated.blank?)
      to_be_investigated.each do |obs_id|
        obs_state = State.find_by_observation_id(obs_id)
        obs_state.state = 'Investigating'
        obs_state.save!
      end
    end
    render :text => true and return
  end
end
