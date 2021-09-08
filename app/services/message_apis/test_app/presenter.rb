module MessageApis::TestApp

  class Presenter
    # Initialize flow webhook URL
    # Sent when an app has been inserted into a conversation, message or the home screen, so that you can render the app.
    def self.initialize_hook(kind:, ctx:)
      type_value = ctx.dig(:values, :type)
      block_type = ctx.dig(:values, :block_type)

      if ctx[:location] == "inbox"
        return {
          # ctx: ctx,
          values: { block_type: block_type },
          definitions: [
            {
              type: "content"
            }
          ]
        }
      end

      definitions = [
        {
          type: "text",
          text: "text text text #{ctx[:values]}",
          align: "left",
          style: "muted"
        },
        {
          name: "open-assessment",
          label: "test test",
          type: "button",
          align: "center",
          width: "full",
          action: {
            type: "frame",
            url: "/package_iframe_internal/TestApp"
          }
        }
      ]

      {
        kind: "initialize",
        definitions: definitions,
        values: ctx[:values]
      }

    end

    # Submit flow webhook URL
    # Sent when an end-user interacts with your app, via a button, link, or text input. This flow can occur multiple times as an end-user interacts with your app.
    def self.submit_hook(params)
      definitions = [
        {
          type: "text",
          text: "Assessments",
          align: "center",
          style: "header"
        }
      ]

      back_button =  {
        "type": "button", 
        "id": "back", 
        "variant": "link", 
        "size": "small", 
        "label": "back", 
        "action": { 
          "type": "submit"
        }
      }

      
      # this is the handler when you receive the event from the iframe (the postEvent via js)
      if params.dig(:ctx, :location) === "messenger" && params.dig(:ctx, :values, "data", "message_key").present?

        k = params.dig(:ctx, :values, "data", "message_key")
        ConversationPart.find_by(key: k )

        definitions = [
          {
            type: "text",
            text: "Assessment complete!",
            align: "center",
            style: "header"
          }
        ]

        return {
          kind: "submit",
          definitions: definitions,
          values: params[:ctx][:values]
        }

      end
              

      conversation = params.dig(:ctx, :package).app.conversations.find_by(key: params.dig(:ctx, :conversation_key) )
      contact = conversation.main_participant

      # only from inbox context
      if params.dig(:ctx, :location) === "inbox"

        if params.dig(:ctx, :current_user).is_a?(Agent)
        
          case params.dig(:ctx, :field, :id)
          when 'contact-assessments'
            a = ListDefinitions.new(user: nil)
            definitions += a.definitions
          when 'assign-assessments'
            a = ListDefinitions.new(user: nil)
            definitions << {
              type: "text",
              text: "Available assessments",
              align: "center",
              style: "muted"
            }
            definitions += a.definitions
          when 'back'
            definitions = definitions + self.initial_definitions
          else
            if params.dig(:ctx, :field, :id).include?("list-item")
              # here you have to add the assessment to the user if that's successful
              # return the initialize
              # this will call the initialize and then the content_hook render
              return {
                kind: "initialize",
                definitions: []
                #values: params[:ctx][:values]
              }
            end
          end

          return {
            kind: "submit",
            definitions: [back_button, definitions].flatten,
            values: params[:ctx][:values]
          }
        end

      end
      

      if (event = params.dig(:ctx, :values, "data", "event")) && event
        case event
        when "calendly.event_scheduled"
          definitions << {
            type: "text",
            text: "Scheduled!",
            align: "center",
            style: "header"
          }
        end
      end

      {
        kind: "submit",
        definitions: definitions,
        values: params[:ctx][:values]
      }
    end

    # Configure flow webhook URL (optional)
    # Sent when a teammate wants to use your app, so that you can show them configuration options before it’s inserted. Leaving this option blank will skip configuration.
    def self.configure_hook(kind:, ctx:)

      conversation = ctx.dig(:package).app.conversations.find_by(key: ctx.dig(:conversation_key) )
      contact = conversation.main_participant
      
      button_label = {
        type: "button", 
        id: "pick-another", 
        variant: "outlined", 
        size: "small", 
        label: "activate", 
        action: { 
          type: "submit"
        }
      }

      if ctx[:location] == "inbox"
        return {
          kind: "initialize",
          definitions: []
          # results: results
        }
      end

      if ctx[:location] == "conversations"

        if ctx.dig(:field, :id)&.include?("list-item")
          return {
            kind: "initialize",
            definitions: [],
            results: {
              assessment_id: ctx.dig(:field, :id)
            }
          }
        end

        a = ListDefinitions.new(user: contact)
        definitions = [button_label]
        definitions += a.definitions
        return { kind: kind, ctx: ctx, definitions: definitions }
      end

    end

    def self.content_hook(kind:, ctx:)
      d = ListDefinitions.new(user: nil)
      definitions = initial_definitions
      definitions += d.contact_assesments
      {
        definitions: definitions
      }
    end

    # Submit Sheet flow webhook URL (optional)
    # Sent when a sheet has been submitted. A sheet is an iframe you’ve loaded in the Messenger that is closed and submitted when the Submit Sheets JS method is called.
    def self.sheet_hook(params)
      { a: 11_111 }
    end

    def self.sheet_view(params)
      @user = params[:user]
      @url = params.dig(:values, :url)
      @conversation_key = params[:conversation_id]
      @message_id = params[:message_id]
      @name = @user[:name]
      @email = @user[:email]

      template = ERB.new <<~SHEET_VIEW
                            <html lang="en">
                              <head>
                                <meta charset="UTF-8">
                                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                                <meta http-equiv="X-UA-Compatible" content="ie=edge">
                                <title>[Calendly] Widget embed API example</title>
                                <style>
                                body {
                                  background: url('https://www.toptal.com/designers/subtlepatterns/patterns/restaurant_icons.png');
                                  font-family: 'Gill Sans', 'Gill Sans MT', Calibri, 'Trebuchet MS', sans-serif;
                                  margin: 0px;
                                }
                                h1 {
                                  font-size: 50px;
                                  text-align: center;
                                }
                                .container {
                                  margin: 0 auto;
                                  width: 100%;
                                }
                                .container p, .container h2 {
                                  text-align: center;
                                }
                                </style>
                              </head>
                              <script>
                                function handleClick(e){
                                  window.parent.postMessage({
                                    chaskiqMessage: true,
                                    type: "TestApp",
                                    status: "submit",
                                    data: <%= params.to_json %>
                                  }, "*")
                                }
                              </script>
                              <body>
                                <div class="container">

                                  <h1>VARS</h1>
                                  <p>user  <%= @user %></p>              
                                  <p>data  <%= params.to_json %></p> 
                                  
                                  <button onclick="handleClick()">click here!</button>
                               
                                  <!-- Copy and Paste Me -->
                                  <div class="glitch-embed-wrap" style="height: 420px; width: 100%;">
                                    <iframe
                                      src="https://glitch.com/embed/#!/embed/hospitable-lyrical-beret?path=README.md&previewSize=100"
                                      title="hospitable-lyrical-beret on Glitch"
                                      allow="geolocation; microphone; camera; midi; vr; encrypted-media"
                                      style="height: 100%; width: 100%; border: 0;">
                                    </iframe>
                                  </div>


                                </div>
                              </body>
                            </html>
      SHEET_VIEW

      template.result(binding)
    end

    def self.initial_definitions
      [
        {
          type: "text",
          text: "Assessments",
          style: "header"
        },
        {"type": "separator"},
        {
          "type": "button", 
          "id": "assign-assessments",
          "variant": "success", 
          "align": "right",
          "size": "small", 
          "label": "Assign assessments", 
          "action": { 
            "type": "submit"
          }
        }
      ]
    end
  end


  # example class
  class ListDefinitions
    attr_accessor :user

    def initialize(user:)
      @user = user
    end

    def contact_assesments
      [
        { "type": "text",
          "text": "Contact' assessments",
          "style": "header" 
        },
        { "type": "data-table",
          "items": (1..5).map do |num|
            { 
              "type": "field-value",
              "field": "Assement #{num}",
              "value": "Value #{num}"
            }
          end
        }
      ]
    end

    def definitions
      [
        { 
          "type": "list", 
          "disabled": false, 
          "items": (1..10).map do |num| 
            { "type": "item",
              "id": "list-item-#{num}",
              "title": "Item #{num}",
              "action": {"type": "submit"}
            }
          end
        }
      ]
    end
  end
end
