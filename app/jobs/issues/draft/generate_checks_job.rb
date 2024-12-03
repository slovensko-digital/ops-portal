class Issues::Draft::GenerateChecksJob < ApplicationJob
  queue_as :default

  def perform(draft)
    draft.checks = llm_generate_checks(draft)
  end

  private

  SYSTEM_PROMPT = <<-LLM
    Your task is to check a problem reported by a person to a civil municipality servant.

    The problem has a title and description and must be checked with various rules written in Slovak.

    Return JSON array with failing checks as hashes with `title`, `description` and `action` keys.
    Do not return the `rule`.
    Do not return anything else than JSON and if there are no problems return empty array `[]`.

    Checks dictionary:

    Title: Parkovanie
    Description: Podnety, ktorý nahlasuje zlé parkovanie vozidiel je potrebné riešiť s mestskou políciou. Táketo podnety Odkaz pre starostu nevie.
    Action: back
    Rules:
     - Podnet nahlasuje zle zaparkované auto a nejde o vrak auta.

    Title: Vrak
    Description: Odstránenie vraku je komplikovaný proces a môže trvať dlhšie. Pripravte sa na to.
    Action: confirm
    Rules:
     - Podnet nahlasuje vrak vozidla a nie iba zle zaparkované auto.

    Title: Vulgarizmy
    Description: Podnet obsahuje vulgarizmy alebo je napísaný nevhodne.
    Action: back
    Rules:
     - Podnet, ktorý obsahuje vulgarizmy sa neakceptuje.

    Title: Nedostatočný popis
    Description: Podnet je popísaný nedostatočne. Skúste ho opísať širšie.
    Action: back
    Rules:
     - Nadpis a popis podnetu musia byť jednoznačné a dostatočne obšírne, aby sa podnet dal spracovať.

  LLM

  def llm_generate_checks(draft)
    conn = Faraday.new(
      url: "https://api.anthropic.com",
      headers: {
        "x-api-key": ENV["ANTHROPIC_API_KEY"],
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
      }
    ) do |f|
      f.adapter :patron
      f.response :json
    end

    res = conn.post("v1/messages") do |req|
      req.body = {
        messages: [
          {
            role: :user,
            content: <<-MSG
             Podnet

             Title:
             #{draft.title}

              Description:
              #{draft.description}
            MSG
          }
        ],
        system: SYSTEM_PROMPT,
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1024
      }.to_json
    end

    JSON.parse(res.body["content"].first["text"])
  end
end
