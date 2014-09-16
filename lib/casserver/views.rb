# -*- coding: utf-8 -*-
# The #.#.# comments (e.g. "2.1.3") refer to section numbers in the CAS protocol spec
# under http://www.ja-sig.org/products/cas/overview/protocol/index.html

# need auto_validation off to render CAS responses and to use the autocomplete='off' property on password field
Markaby::Builder.set(:auto_validation, false)

# disabled XML indentation because it was causing problems with mod_auth_cas
#Markaby::Builder.set(:indent, 2)

module CASServer::Views

  def image(name)
    "/themes/#{current_theme}/images/#{name}"
  end

  def page_header
    <<-HEADER
      <header class="toplevel">
        <div class="wrapper">
          <div class="logo-wrapper">
             <a href="#" class="logo"><img alt="Logo" src="#{image('logo.png')}"></a>
          </div>
          <nav>
            <li><a id="admin_link" >Administration</a></li>
            <li><a id="portal_link" target="_blank">Purchasing Portal</a></li>
          </nav>
          <hr>
        </div>
      </header>
    HEADER
  end

  def page_footer
    <<-FOOTER
      <div id="footer">
        <div class="wrapper">
          <div id="need-help-info">
            <h6>Need Help?</h6>
            <p id="need-help-info-content">
              <span class="line">
                <strong>Call</strong>
                <a href="tel:+61294224730">+61 2 9422-4730</a>
                9am &ndash; 5pm EST (Mon &ndash; Fri),
              </span>
              <span class="line">
                <strong>or email</strong>
                <a href="mailto:accounts@dentalcorp.com.au">accounts@dentalcorp.com.au</a>
              </span>
            </p>
          </div>
        </div>
      </div>
    FOOTER
  end

  def layout
    # wrap as XHTML only when auto_validation is on, otherwise pass right through
    if @use_layout
      xhtml_strict do
        head do
          title { "#{organization} #{_(' Central Login')}" }
          script(:type => "text/javascript", :src => "/themes/modernizr-1.7.min.js?20111109") { }
          script(:type => "text/javascript", :src => "/themes/jquery-1.4.2.min.js?20111109") { }
          script(:type => "text/javascript", :src => "/themes/jquery.placeholder.min.js?20111109") { }
          script(:type => "text/javascript", :src => "/themes/application.js?20111109") { }
          link(:rel => "stylesheet", :type => "text/css", :href => "/themes/cas.css?20111109")
          link(:rel => "stylesheet", :type => "text/css", :href => "/themes/#{current_theme}/theme.css?20111104")
          link(:rel => "icon", :type => "image/png", :href => "/themes/#{current_theme}/favicon.png") if
            File.exists?("#{$APP_ROOT}/public/themes/#{current_theme}/favicon.png")
        end
        body(:onload => "if (document.getElementById('username')) document.getElementById('username').focus()") do
          div(:class => "container") do
            self << page_header
            div(:class => "content") do
              div(:class => "wrapper") do
                tag!("header", :class => "page") do
                  h1(:class => "list-header") { "Log In" }
                end
                tag!(:section, :class => "page") do
                  self << yield
                end
              end
            end
            self << page_footer
          end
        end
      end
    else
      self << yield
    end
  end


  # 2.1.3
  # The full login page.
  def login
    @use_layout = true

    <<-MAIN
      <div class="wrapper">
        <div id="feature">
          <div id="intro">
            <h1>Welcome to the <strong>Payments Portal</strong></h1>
            #{message if @message}
            #{login_form}
          </div>
        </div>
      </div>
    MAIN
  end

  # Just the login form.
  def login_form
    submitbutton = _("Please wait...")

    <<-LOGIN
      <form action="#{@form_action || "/login"}" method="post" onsubmit="submitbutton = document.getElementById('login-submit'); submitbutton.value='#{submitbutton}'; submitbutton.disabled=true; return true;" class="login-form">
        <input id="lt" name="lt" type="hidden" value="#{@lt}">
        <input id="service" name="service" type="hidden" value="#{@service}">
        <p>
          <input class="title" id="username" name="username" placeholder="Username" accesskey="u" size="30" type="text">
        </p>
        <p>
          <input class="title" id="password" name="password" placeholder="Password" accesskey="p" size="30" type="password">
        </p>
        <p class="action">
          <input id="login-submit" class="button primary" name="commit" accesskey="l" type="submit" value="Sign In">
        </p>
      </form>
    LOGIN
  end

  def message
    <<-MSG
      <p class="messagebox #{@message[:type]}">#{@message[:message]}</p>
    MSG
  end

  # 2.3.2
  def logout
    @use_layout = true

    table(:id => "login-box") do
      tr do
        td(:colspan => 2) do
          div(:id => "headline-container") do
            strong organization
            text _(" Central Login")
          end
        end
      end
      if @message
        tr do
          td(:colspan => 2, :id => "messagebox-container") do
            div(:class => "messagebox #{@message[:type]}") { @message[:message] }
            if @continue_url
              p do
                a(:href => @continue_url) { @continue_url }
              end
            end
          end
        end
      end
    end
  end

  # 2.4.2
  # CAS 1.0 validate response.
  def validate
    if @success
      text "yes\n#{@username}\n"
    else
      text "no\n\n"
    end
  end

  # 2.5.2
  # CAS 2.0 service validate response.
  def service_validate
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username.to_s.to_xs}
          @extra_attributes.each do |key, value|
            tag!(key) {serialize_extra_attribute(value)}
          end
          if @pgtiou
            tag!("cas:proxyGrantingTicket") {@pgtiou.to_s.to_xs}
          end
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end

  # 2.6.2
  # CAS 2.0 proxy validate response.
  def proxy_validate
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username.to_s.to_xs}
          @extra_attributes.each do |key, value|
            tag!(key) {serialize_extra_attribute(value)}
          end
          if @pgtiou
            tag!("cas:proxyGrantingTicket") {@pgtiou.to_s.to_xs}
          end
          if @proxies && !@proxies.empty?
            tag!("cas:proxies") do
              @proxies.each do |proxy_url|
                tag!("cas:proxy") {proxy_url.to_s.to_xs}
              end
            end
          end
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end

  # 2.7.2
  # CAS 2.0 proxy request response.
  def proxy
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxySuccess") do
          tag!("cas:proxyTicket") {@pt.to_s.to_xs}
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxyFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end

  def configure
  end

  protected
    def themes_dir
      File.dirname(File.expand_path(__FILE__))+'../themes'
    end
    module_function :themes_dir

    def current_theme
      $CONF.theme || "simple"
    end
    module_function :current_theme

    def organization
      $CONF.organization || ""
    end
    module_function :organization

    def infoline
      $CONF.infoline || ""
    end
    module_function :infoline

    def serialize_extra_attribute(value)
      if value.kind_of?(String) || value.kind_of?(Numeric)
        value
      else
        "<![CDATA[#{value.to_yaml}]]>"
      end
    end
    module_function :serialize_extra_attribute
end

if $CONF.custom_views_file
  require $CONF.custom_views_file
end
