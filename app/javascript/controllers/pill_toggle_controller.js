import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "pill" ]
  toggle(event) {
    console.log("coucou")
    console.log(event)
    const pill = event.target
    const checkbox = pill.querySelector('input[type="checkbox"]') // On sélectionne l'input caché

    // Toggle la classe pour la couleur et la transparence
    pill.classList.toggle("bg-blue-300") // Quand sélectionnée, couleur plus claire
    pill.classList.toggle("bg-blue-500") // Quand sélectionnée, couleur plus foncée
    pill.classList.toggle("opacity-75")  // Pour rendre plus opaque quand sélectionnée

    // Affiche la croix si la pilule est sélectionnée
    const cross = pill.querySelector('.cross')
    if (checkbox.checked) {
      cross.classList.remove("hidden") // Affiche la croix
    } else {
      cross.classList.add("hidden") // Masque la croix
    }

    // On coche/décoche la case cachée
    checkbox.checked = !checkbox.checked
  }
}
