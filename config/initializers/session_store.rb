Rails.application.config.session_store :cookie_store,
  key: "_chore_splitter_session_#{Rails.env}", # avoid collisions across envs
  secure: Rails.env.production?,               # required for cookies over HTTPS on Heroku
  same_site: :lax,                             # good default; change to :none if you truly go cross-site
  expire_after: 14.days
