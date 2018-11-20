Capybara.add_selector(:gridpanel) do
  xpath do |name|
    ".//div[contains(@id, '#{name}')][not(contains(@id, 'splitter'))] | "\
    ".//div[contains(@id, '#{name.camelize(:lower)}')]"\
    "[not(contains(@id, 'splitter'))]"
  end
end

Capybara.add_selector(:msg) do
  xpath do
    "//div[@id='msg-div']"
  end
end

Capybara.add_selector(:body) do
  xpath do
    ".//div[@data-ref='body']"
  end
end

Capybara.add_selector(:input) do
  xpath do |name|
    "//input[@name='#{name}']"
  end
end

Capybara.add_selector(:status) do
  xpath do |name|
    "//div[contains(@id, 'statusbar')]//div[text()='#{name}']"
  end
end

Capybara.add_selector(:btn) do
  xpath do |name|
    ".//span[text()='#{name}']"
  end
end

Capybara.add_selector(:refresh) do
  xpath do
    ".//div[contains(@class, 'x-tool-refresh')]"
  end
end

Capybara.add_selector(:gridcolumn) do
  xpath do |name|
    ".//span[contains(@class, 'x-column-header')][text()='#{name}']/.."
  end
end
