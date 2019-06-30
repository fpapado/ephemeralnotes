module Page.About exposing (view, viewAddToHomeScreen, viewPitch)

import Html exposing (..)
import Html.Attributes as HA exposing (..)
import Route
import Ui exposing (..)


view : { title : String, content : Html msg }
view =
    { title = "About"
    , content = viewContent
    }


viewContent : Html msg
viewContent =
    div [ class "f4 lh-copy" ]
        [ centeredContainer
            []
            [ div [ class "vs4 vs5-ns" ]
                [ div [ class "vs3" ]
                    [ heading 1 [] [ text "About" ]
                    , viewPitch
                    ]

                -- , viewAddToHomeScreen
                , viewFaq
                ]
            ]
        ]


viewPitch =
    paragraph [ class "measure" ] [ text "Ephemeral is a web app for writing down words and their translations, as you encounter them. It works offline and everything is stored locally, on your device." ]


viewAddToHomeScreen =
    div [ class "vs3" ]
        [ subHeading 2
            []
            [ text "Add to Home Screen" ]
        , paragraph
            [ class "measure" ]
            [ text "You can add Ephemeral to your home screen for quicker access and standalone use. It will always be available offline through your web browser." ]
        ]


viewFaq =
    div [ class "vs4 vs5-ns" ]
        [ div [ class "vs3" ]
            [ subHeading 3 [] [ text "Who created this? Why?" ]
            , paragraph []
                [ text "The app is made by "
                , a [ href "https://twitter.com/isfotis", class "color-accent" ] [ text "Fotis Papadogeorgopoulos" ]
                , text " (that's me, hi!). I made this originally when I immigrated to Finland and wanted a way to connect words with events and the world around me. I make this app in my free time."
                ]
            ]
        , div [ class "vs3" ]
            [ subHeading 3 [] [ text "Can I contact you?" ]
            , paragraph [] [ text "If you're using this app, I'll be happy to hear about it! Has it been useful? What have you done with it? Is there something specific that could help you make better use of it?" ]
            , paragraph [] [ text "You can find me in the following places: " ]
            , ul [ class "vs2 pl4" ]
                [ li [] [ a [ class "color-accent", href "https://twitter.com/isfotis" ] [ text "On Twitter @isfotis" ] ]
                , li [] [ a [ class "color-accent", href "https://github/fpapado" ] [ text "On Github @fpapado" ] ]
                , li [] [ a [ class "color-accent wb-all", href "mailto:fotis@fpapado.com" ] [ text "Via email to ephemeral@fpapado.com" ] ]
                ]
            ]
        , div [ class "vs3" ]
            [ subHeading 3 [] [ text "Can I donate to the development?" ]
            , paragraph [] [ text "If you have used this app and found it useful, you can donate through buy me a coffee." ]
            , paragraph []
                [ text "To be fully transparent: I am partially compensated for my work through the "
                , a [ href "https://spiceprogram.org/", class "color-accent" ] [ text "Chillicorn open source program" ]
                , text ". Thus, I'm not reliant on donations. Still, if you do have the inclination, I will be happy for them!"
                ]
            , paragraph []
                [ text "Other than that, I would happily accept help in learning Finnish!" ]
            ]
        , div [ class "vs3" ]
            [ subHeading 3 [] [ text "Can I contribute to the development?" ]
            , paragraph []
                [ text "Probably yes! I want to keep a narrow scope for the app, around effectively and efficiently writing down words. If you have ideas that can fit in that context, open an "
                , a [ class "color-accent", href "https://github.com/fpapado/ephemeralnotes/issues" ] [ text "issue on the Github repository" ]
                , text " and let's chat. It doesn't even have to be code; text suggestions and design are just as welcome."
                ]
            ]
        , div [ class "vs3" ]
            [ subHeading 3 [] [ text "Where is the data stored again?" ]
            , paragraph []
                [ text "Locally, on your device. Web browsers, like Chrome, Firefox and Safari, provide ways to store data, local to a device per website. The storage limit is around 50MB, which is plenty of words and locations." ]
            , paragraph []
                [ text "Apart from the initial code required to run the application, no other data is transmitted to the server. No analytics, no syncronisation, nothing. In fact there barely is a server!" ]
            , paragraph []
                [ text "The entries stored are typically permanent, though a browser may clear data if you are low on storage and haven't accessed the content in a while. This is the reason we provide the "
                , a [ Route.href Route.Data, class "color-accent" ] [ text "Data page." ]
                , text "You can export your data into a different service if you want extra peace of mind. As a bonus, you can also transfer entries between devices."
                ]
            ]
        , div [ class "vs3" ]
            [ subHeading 3 [] [ text "What's \"add to home screen\"?" ]
            , paragraph [] [ text "Add to Home Screen is a relatively modern way of installing an aplication. Instead of having to access the app store, and download multiple MBs of data, you only need to access the website. From then on, the browser will prompt you to add the app to the home screen. The app functions similar to a standalone app (works offline, has permanent storage)." ]
            , paragraph [] [ text "The benefit of this approach is that you can access the app on most devices with a web browsers, including laptops, tablets, desktops etc." ]
            ]
        , div [ class "vs3" ]
            [ subHeading 3 [] [ text "Why \"ephemeral\"?" ]
            , paragraph [] [ text "Ephemeral is one of those anglicised Greek words. It means \"lasting a short time, fleeting\". I was thinking a lot about memories of places when writing that. Also, I found the word a fun contrast to the temporary storage of entries in a browser." ]
            ]
        ]
