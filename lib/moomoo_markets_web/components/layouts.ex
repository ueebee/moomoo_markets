defmodule MoomooMarketsWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use MoomooMarketsWeb, :controller` and
  `use MoomooMarketsWeb, :live_view`.
  """
  use MoomooMarketsWeb, :html

  embed_templates "layouts/*"
end
