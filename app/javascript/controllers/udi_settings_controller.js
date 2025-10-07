import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="udi-settings"
export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    // console.log("UDI Settings controller connected")
  }

  enableAllForDate(event) {
    const date = event.target.dataset.date
    // console.log("Enabling all slots for date:", date)
    
    // Find all checkboxes for this specific date
    const checkboxes = this.element.querySelectorAll(`input[name*="[${date}]"]`)
    // console.log("Found checkboxes:", checkboxes.length)
    
    checkboxes.forEach(checkbox => {
      if (!checkbox.disabled) {  // Don't change already booked slots
        checkbox.checked = true
        // console.log("Enabled checkbox:", checkbox.value)
      }
    })
    
    this.updateVisualState()
  }

  disableAllForDate(event) {
    const date = event.target.dataset.date
    // console.log("Disabling all slots for date:", date)
    
    // Find all checkboxes for this specific date  
    const checkboxes = this.element.querySelectorAll(`input[name*="[${date}]"]`)
    // console.log("Found checkboxes:", checkboxes.length)
    
    checkboxes.forEach(checkbox => {
      if (!checkbox.disabled) {  // Don't change already booked slots
        checkbox.checked = false
        // console.log("Disabled checkbox:", checkbox.value)
      }
    })
    
    this.updateVisualState()
  }

  resetAll(event) {
    event.preventDefault()
    
    if (confirm("Are you sure you want to enable all slots for this week?")) {
      // Find all checkboxes in the form
      const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
      // console.log("Resetting all checkboxes:", checkboxes.length)
      
      checkboxes.forEach(checkbox => {
        if (!checkbox.disabled) {  // Don't change already booked slots
          checkbox.checked = true
        }
      })
      
      this.updateVisualState()
    }
  }

  updateVisualState() {
    // Update the visual appearance of containers based on checkbox state
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    
    checkboxes.forEach(checkbox => {
      const container = checkbox.closest('.flex')
      if (!container) return
      
      const isChecked = checkbox.checked
      const isDisabled = checkbox.disabled
      
      // Remove existing state classes
      container.classList.remove('bg-red-50', 'border-red-200', 'bg-green-50', 'border-green-200', 'bg-gray-100', 'border-gray-300')
      
      // Apply new state classes
      if (isDisabled) {
        container.classList.add('bg-gray-100', 'border-gray-300')
      } else if (isChecked) {
        container.classList.add('bg-green-50', 'border-green-200')
      } else {
        container.classList.add('bg-red-50', 'border-red-200')
      }
    })
  }

  checkboxChanged(event) {
    // console.log("Checkbox changed:", event.target.value, "checked:", event.target.checked)
    this.updateVisualState()
  }
}