# Connect Starter Package

## Setup
- Install [Homebrew](https://brew.sh/)
- Install Postgres
 - `brew install postgresql`
   - If you have problem with homebrew after OSX upgrade to Yosemite, run following commands
   - `cd /usr/local/Library`
   - `git pull origin master`
 - Start Database: `pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start`
 - Setup User: Create "postgres" user: `/usr/local/Cellar/postgresql/9.3.5/bin/createuser -s postgres`
   - Version number of postgresql may be different, highlighted in red. Check install by typing `psql --version`
 - Log into psql and change the postgres users password `psql -U postgres`
 - Change the postgres password `ALTER USER postgres WITH PASSWORD 'root';`
 - Exit out of postgres `\q`
- Install [Redis](https://redis.io/)
  - `brew install redis`
  - Start Server: `redis-server`
- Install [PgAdmin](https://www.pgadmin.org/) or [Postico](https://eggerapps.at/postico/)
- Install [RVM](https://rvm.io/rvm/install)
  - Install RVM with `\curl -sSL https://get.rvm.io | bash`
  - From terminal run `source ~/.bash_profile`
  - If you run into brew permission issues, please try the following command: `sudo chown -R `*whoami*`:admin/usr/local/bin"` Replace *whoami* with your current terminal user. My terminal screen reads as follows: Karols-Macbook-Air:zhub kchudy$. In this case kchudy would replace '*whoami*'. If rvm install ruby still throws permission errors remove homebrew and reinstall the latest version by following the below steps:
    - `brew update`
    - `rm -rf /usr/local/Cellar /usr/local/.git && brew cleanup`
    - `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
  - Install Ruby
    - Install ruby-2.3.1 with `rvm install ruby-2.3.1 --disable-binary`
  - Install Bundler
    - `gem install bundler`
  - Clone the Repository
    - `git clone https://github.com/zuora/connect-starter-package.git`

## Configuration & Running the Starter Package
- config/initalizers/connect.rb
  - Reference Connect Gem Documentation for available options
- config/database.yml
  - Insert Database Credentials
- Run `bundle install`
- Run `rake db:create`
- Run `rake db:migrate`
- Start the server with `rails s`

## Resque

### Worker
The starter package includes a basic example of a worker that creates records in the database from subscription queries
```ruby
class SubscriptionQueryWorker
  attr_accessor :schema

  def self.queue
    @queue = :subscription_query_worker
  end

  def self.perform(appinstance_id)
    appinstance = ZuoraConnect::AppInstance.find(appinstance_id)
    appinstance.new_session()
    subscription_query = SubscriptionQuery.new(appinstance)
    subscription_query.execute
  end
end
```
### Queue Jobs
Jobs can be queued using the below code snippet
```ruby
Resque.enqueue(SubscriptionQueryWorker, Thread.current[:appinstance].id)
```

## Datatables

### Datatable Files
Create a new datatable file modeled after the example (app/datatables/products_datatable.rb). Name the file after the plural version of the object you wish to associate this table with.

_This file can be generated using `rails g datatable {Model}`_

There will be 7 methods that need modification in this file

**initialize** - This method handles pulling down the correct data based on filters from the user
```ruby
def initialize(view)
 @view = view
 @total_products = Product.count(:all)_ #Needs to be changed
 @products = Product.select(select_string)_ #Needs to be changed
 @products.where(search_string, search: "%#{params[:sSearch].to_s.downcase}%")
 @products.order("#{sort_column} #{sort_direction}")
 @products = @products.where(:id => params["product_name"]) if !params["product_name"].blank?_ #Needs to be changed
 @filtered_total = @products.size
 @products = @products.page(page).per_page(per_page)
end
```
**as\_json** - This is how the data is sent to through the API route when calld by the frontend. The only modification needed here should be the name change of 2 variables
```ruby
def as_json(options = {})
  {
    sEcho: params[:sEcho].to_i,
    iTotalDisplayRecords: @filtered_total,
    aaData: data,
    iTotalRecords: @total_instances,
  }
end
```

**data** - This is how the data is mapped and what data is being pulled out
```ruby
def data
 @products.map do |product|
   {
     DT_RowId: product.id.to_s,
     DT_RowClass: nil,
     DT_RowAttr: { },
     "products__id" => product.id, #Needs to be changed
     "products__name" => product.name, #Needs to be changed
     "products__price" => product.price, #Needs to be changed
     "products__category" => product.category, #Needs to be changed
     "products__zuora_id" => product.zuora_id, #Needs to be changed
     #This is only needed if you want the datatable to show actions
     products_actions: actions(product),
     #This is only needed if you want the datatable to support grid view
     "grid_view" => tile(product),
   }
 end
end
```

**actions** - Actions pulls in an html file and can be used to have record specific links for various CRUD operations. This method can be deleted if it is not used in the above data method
```ruby
def actions(product)
  if params[:table_view_mode] == 'table'
    render(:partial=>"products/actions.html.erb", locals: { product: product} , :formats => [:html])
  end
 end
```
**sort\_column** - Change the map field to match the object
```ruby
def sort_column
 col = [*0..params[:iColumns].to_i-1].map{|i| params["mDataProp_#{i}"].gsub("__", ".") if params["bSortable_#{i}"] != 'false' }[params[:iSortCol_0].to_i]
 if !col.blank?
   object, field = col.split('.')
   if !field.blank? && !object.blank?
     map = {"Product" => Product} #Needs to be changed
     field_type = map[object.classify].column_for_attribute(field).type
     return [:string, :text].include?(field_type) ? "lower(#{col})" : col
   else
     return col
   end
  else
   return  "products.id"
 end
end
```
**search\_string** - Modify this to change what fields are searchable. The syntax follows general sql(postgres)
```ruby
def search_string
  "to_char(products.id, '999999999') LIKE :search OR
  lower(products.name) LIKE :search OR
  lower(products.category) LIKE :search OR
  products.price LIKE :search" #Needs to be changed
end
```

**select\_string** - Modify this to change what fields are selected. The syntax follows general sql(postgres)
```ruby
def select_string #Needs to be changed
  "products.*"
end
```

**tile** - tile pulls in an html partial that represents a tile to use for the record. This method can be deleted if it is not used in the above data method
```ruby
def tile(object)
  if params[:table_view_mode] == 'grid'
    render(:partial=>"products/tile.html.erb", locals: { product: product} , :formats => [:html])
  end
end
```

### Controller Setup
In the appropriate action that the datatable should be placed in add the following line of code
```ruby
respond_to do |format|
  format.html {  }
  format.json { render json: ::ProductsDatatable.new(view_context) }
  format.js { }
end
```

### View Setup
Insert the below snippet into the corresponding view file
```ruby
<% table_filters = [{"name" => "Product Name", "cache" => false, "prompt" => "Product Name", "width" => "200px", "type" => "select", "values" => Product.all.order(name: :asc).pluck(:name, :id)}] %>
<% table_actions = capture do %>
 <div class="btn-group">
   <%= link_to new_product_path, :remote => true, :class => 'btn btn-default' do %>
     <span class="fa fa-plus"></span> New Product
   <% end %>
 </div>
<% end %>
<% columns  =[
 { "title": "Id", "data": "products__id",'visible': true },
 { "title": "Name", "data": "products__name",'visible': true },
 { "title": "Type", "data": "products__category",'visible': true },
 { "title": "Price", "data": "products__price",'visible': true },
 { "title": "Zuora Id", "data": "products__zuora_id",'visible': true },
 { "title": "Actions", "data": "products_actions", "class": "center", "bSortable": false,  "width": "250px" }
] %>
<%= render(:partial=>"shared/table.html.erb", locals: {:table_name => "products", :aoData => [], :columns => columns, :sort => [[ "product_id", "asc" ]], :table_filters => table_filters, :table_views => {:table => true, :grid =>false}, :initial_size => 25, :table_actions => table_actions, :table_url =>  products_path(format: "json") }.merge(request.query_parameters), :formats => [:html])  %>
```

#### table_filters
An array of hashes with all the related options for the filter to create. Each option is explained below

| Option |                          Description                          |                                                                   Values or Type                                                                    |                                                                                           Example                                                                                           |
| ------ | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| name   | Used to determined the id for the element                     | String                                                                                                                                              | `{"name" => "product_name"}`                                                                                                                                                                |
| cache  | Set to cache the user's selection for this filter in a cookie | true/false                                                                                                                                          | `{"name" => "product_name","cache" => true}`                                                                                                                                                |
| prompt | Text in the filter that the user sees                         | string                                                                                                                                              | `{"name" => "product_name","prompt" => "Product Name"}`                                                                                                                                     |
| width  | Width of the filter element                                   | [Reference CSS width attribute](http://www.w3schools.com/cssref/pr_dim_width.asp)                                                                                                                       | `{"name" => "product_name","type" => "select", "width" => "200px"}`                                                                                                                         |
| type   | Element type                                                  | checkbox, select, or boolean                                                                                                                        | `{"name" => "product_name","type" => "select"}`                                                                                                                                             |
| values | Values to use in the filter element                           | Checkbox - Array or Array of Arrays\*, Select - Array of Arrays\*, \*Array of Arrays should be formatted like: [["Frontend View", "Backend Value"]] | `{"name" => "product_name","type" => "checkbox", values => ["Val1", "Val2"]} view source`<br>`{"name" => "product_name","type" => "select", values => [["Product 1", 1],["Product 2", 2]]}` |

#### table_actions
Table actions is an html block to insert in the datatable partial

#### columns
An array of hashes that contains options for each column to insert in the datatable

| Option  |                                     Description                                      | Values or Type |                          Example                          |
| ------- | ------------------------------------------------------------------------------------ | -------------- | --------------------------------------------------------- |
| title   | Used for the table header label                                                      | String         | `{ "title": "Id", "data": "products__id",'visible': true }` |
| data    | Used to map this header to the returned field from the datatable class created above | String         | `{ "title": "Id", "data": "products__id",'visible': true }` |
| visible | Used to determine if the column should be visible                                    | boolean        | `{ "title": "Id", "data": "products__id",'visible': true }` |

#### Partial Options
Options can be set using the locals field in the partials render call

|    Option     |                                                                 Description                                                                 | Values or Type |                         Example                         |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------------------------- |
| table_name    | Used to set the table's ID                                                                                                                  | String         | `{:table_name => "products"}`                           |
| aoData        | Used to set the pre-selected values to pass to the datatable class                                                                          | String         | `{:aoData =>  [{ "name": "product_id", "value": "1"}]}` |
| columns       | Columns to use in the datatable                                                                                                             | array          | Reference above section on columns                      |
| sort          | Column to sort on initially                                                                                                                 | array          | `{:sort => [[ "product_id", "asc" ]]}`                  |
| table_filters | Filters to use in the datatable                                                                                                             | array          | Reference above section on filters                      |
| table_views   | Views available to the datatable<br> In order to use grid the datatable class must support it. See above documenation on how to set this up     | hash           | `{:table_views => {:table => true, :grid =>false}}`     |
| initial_size  | Initial page size for the table                                                                                                             | integer        | `{:initial_size => 25}`                                 |
| table_actions | Actions to insert in the table related to the table                                                                                         | block          | Reference above section on table Actions                |
| table_url     | URL to the controller that returns the datatable AJAX response                                                                              | url            | `{:table_url =>  products_path(format: "json") }`       |

## Modals

### controller
Add a format line to the action that should display the modal
```ruby
 def show
  respond_to do |format|
   format.html {  }
   format.js { }
  end
 end
```

### View
#### show.js.erb
Create a file in the views directory for the specified action in the controller in this example "show"
```js
<%  render(:file=>"products/show", locals: {}, :formats => [:html] ) %>
```
#### show.html.erb
Create a file in the view directory for the specified action in the controller in this example "show"
```html
<% if request.format == :html %>
#This denotes what page should be loaded behind the modal if the modal route is linked to directly
  <%= render(:file=>"products/index", :formats => [:html]) %>
<% end %>
<% content_for :modal do %>
  <div class="modal-dialog" style="width: 800px">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
        <h4 class="modal-title"><%= @product.name %></h4>
      </div>
      <div class="overlay">
        <i id="loading_form_icon" class="glyphicon glyphicon-refresh glyphicon-spin"></i>
      </div>
      <div class="modal-body z-background">
        <div class="row">
          <div class="col-md-12">
            <p><strong>Name:</strong> <%= @product.name %></p>
            <p><strong>Category:</strong> <%= @product.category %></p>
            <p><strong>Price:</strong> <%= @product.price %></p>
            <p><strong>Zuora ID:</strong> <%= @product.zuora_id %></p>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
<% end %>
#Any additional Javascript can be placed in the below block. The first line is required in order to have the modal popup.
<% content_for :scripts do %>
  $('#z_hub_modal').modal("show");
<% end %>
```

## APIs
### Authentication
Authentication is done through the Connect gem which is automatically included in the starter package. The gem generates unique tokens for every app instance that is setup against the application. These tokens are used to make API calls to the application directly. In order to use this included authentication mechanism the base API controller uses the before filter `before_filter :authenticate_app_api_request`

### Controller
An example controller is provided below that can be modeled after when setting up your own apis. It is important to note that all API controllers should inherit from the **api_base_controller**. This will ensure that all common functionality is pulled down to every API controller you create. The base controller includes basic features such as the automatic includement of CORS filtering, Authentication, and error handling of many common errors. It is worth noting that if there is any logic that should take place before any API action ever executes it can be appended to the **api_base_controller**.

An example API Controller can be seen below
```ruby
#Inherits from the base api controller
class Api::V1::ProductsController < Api::V1::APIBaseController
  #Logic to execute before the controller action happens
  before_action :set_product, only:  [:show]

  def index
    @products = Product.all
    @unfiltered_size = @products.size
    #The below can be reused among all API controllers and allows for basic pagination to exist
    if params[:page].nil?
      @page = 1
    else
      @page = params[:page].to_i
    end
    if params[:page_length].nil?
      @page_length = 20
    else
      @page_length = params[:page_length].to_i
    end
    @products = @products.page(@page).per_page(@page_length)

    respond_to do |format|
      format.json {render :status => :ok}
    end
  end

  def show
    respond_to do |format|
      format.json {render :status => :ok}
    end
  end

  private
    #Before action to find the related object to perform logic on
    def set_product
      @product = Product.find(params[:id])
    end
end
```

### Route
The new controller actions must be added to the routes file in order to work. Notice the below route file for an example

```ruby
Rails.application.routes.draw do
  root :to => "products#index"
  resources :products
  app_admin = lambda { |request| request.session["#{request.session['appInstance']}::admin"]}
  constraints app_admin do
    namespace :admin do
      get :delayedjob, to: 'application#delayedjob'
      match "/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]
      resources :app_instances, :only => [:index]
    end
  end
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :products, :only => [:index, :show] #Needs to be changed
    end
  end
  match '*path', via: :all, to: 'products#index'
end
```

### View(JBuilder)
JBuilder is a gem that allows for easy API creation by simplifying the creation of a JSON payload. The documentation for JBuilder can be referenced [here](https://github.com/rails/jbuilder) for additional options. Note the example below on creating an API to list product attributes
```ruby
json.id product.id
json.name product.name
json.description product.price
```
