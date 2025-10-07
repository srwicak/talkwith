import { Controller } from "@hotwired/stimulus"

// FORCE DEBUG - test if file loads
// console.log("📁 UDI CALENDAR FILE LOADING...");
// alert("📁 FILE LOADING!");

// Connects to data-controller="udi-calendar"
export default class extends Controller {
  static targets = ["selectedDate", "selectedSlot", "submitBtn", "summary", "summaryText", "nameField", "emailField", "subjectField", "descriptionField"]
  
  connect() {
    // Expose to window for onclick fallback
    window.udiCalendar = this;
    // alert("🚀 UDI CALENDAR CONNECTED!");
    // console.log("=== UDI CALENDAR CONNECTED ===");
    // console.log("Available targets:");
    // console.log("- selectedDateTarget:", this.hasSelectedDateTarget);
    // console.log("- selectedSlotTarget:", this.hasSelectedSlotTarget);
    // console.log("- submitBtnTarget:", this.hasSubmitBtnTarget);
    // console.log("- nameFieldTarget:", this.hasNameFieldTarget);
    // console.log("- emailFieldTarget:", this.hasEmailFieldTarget);
    // console.log("- subjectFieldTarget:", this.hasSubjectFieldTarget);
    // console.log("- descriptionFieldTarget:", this.hasDescriptionFieldTarget);
    // console.log("==============================");
    // console.log("Available targets:");
    // console.log("- selectedDateTarget:", this.hasSelectedDateTarget);
    // console.log("- selectedSlotTarget:", this.hasSelectedSlotTarget);
    // console.log("- submitBtnTarget:", this.hasSubmitBtnTarget);
    // console.log("- nameFieldTarget:", this.hasNameFieldTarget);
    // console.log("- emailFieldTarget:", this.hasEmailFieldTarget);
    // console.log("- subjectFieldTarget:", this.hasSubjectFieldTarget);
    // console.log("- descriptionFieldTarget:", this.hasDescriptionFieldTarget);
    // console.log("==============================");
    this.validateForm();
    
    // Add event listeners to form fields for real-time validation
    this.element.addEventListener('input', () => this.validateForm());
    this.element.addEventListener('change', () => this.validateForm());
  }
  
  disconnect() {
    if (window.udiCalendar === this) {
      window.udiCalendar = null;
    }
  }
  
  validateForm() {
    // Check if we have a time slot selected
    const hasTimeSlot = this.selectedDateTarget.value && this.selectedSlotTarget.value;
    
    // Check form fields with more lenient validation
    let hasValidForm = true;
    let fieldStatus = {};
    
    // Check each field if it exists with relaxed requirements
    if (this.hasNameFieldTarget) {
      const name = this.nameFieldTarget.value.trim();
      fieldStatus.name = { value: name, length: name.length, valid: name.length >= 1 };
      if (name.length < 1) hasValidForm = false; // Changed from 2 to 1
    }
    
    if (this.hasEmailFieldTarget) {
      const email = this.emailFieldTarget.value.trim();
      fieldStatus.email = { value: email, length: email.length, hasAt: email.includes('@'), valid: email.includes('@') && email.length >= 5 };
      // More basic email validation
      if (!email.includes('@') || email.length < 5) hasValidForm = false;
    }
    
    if (this.hasSubjectFieldTarget) {
      const subject = this.subjectFieldTarget.value.trim();
      fieldStatus.subject = { value: subject, length: subject.length, valid: subject.length >= 1 };
      if (subject.length < 1) hasValidForm = false; // Changed from 3 to 1
    }
    
    if (this.hasDescriptionFieldTarget) {
      const description = this.descriptionFieldTarget.value.trim();
      fieldStatus.description = { value: description, length: description.length, valid: description.length >= 1 };
      if (description.length < 1) hasValidForm = false; // Changed from 10 to 1
    }
    
    // Enable button if we have time slot AND form is mostly filled
    const shouldEnable = hasTimeSlot && hasValidForm;
    this.submitBtnTarget.disabled = !shouldEnable;
    
    // console.log("=== VALIDATION DEBUG ===");
    // console.log("Time Slot Selected:", { 
    //   hasTimeSlot, 
    //   selectedDate: this.selectedDateTarget.value,
    //   selectedSlot: this.selectedSlotTarget.value
    // });
    // console.log("Field Status:", fieldStatus);
    // console.log("Form Valid:", hasValidForm);
    // console.log("Button Should Enable:", shouldEnable);
    // console.log("Button Disabled State:", this.submitBtnTarget.disabled);
    // console.log("========================");
  }
  
  selectSlot(event) {
    const button = event.currentTarget;
    const date = button.dataset.date;
    const slot = button.dataset.slot;
    const session = button.dataset.session;
    const dateObj = new Date(date);
    
    // console.log("=== SLOT SELECTION ===");
    // console.log("Button clicked:", button);
    // console.log("Date:", date);
    // console.log("Slot:", slot);
    // console.log("Session:", session);
    // console.log("Button datasets:", button.dataset);
    // console.log("======================");
    
    // Remove previous selections
    document.querySelectorAll('.slot-btn').forEach(btn => {
      btn.classList.remove('border-purple-500', 'bg-gradient-to-br', 'from-purple-100', 'to-blue-100', 'ring-2', 'ring-purple-400', 'shadow-lg');
      btn.classList.add('border-gray-200', 'bg-white');
    });
    
    // Highlight selected slot with beautiful styling
    button.classList.remove('border-gray-200', 'bg-white');
    button.classList.add('border-purple-500', 'bg-gradient-to-br', 'from-purple-100', 'to-blue-100', 'ring-2', 'ring-purple-400', 'shadow-lg');
    
    // Update hidden fields
    this.selectedDateTarget.value = date;
    this.selectedSlotTarget.value = slot;
    
    // console.log("Hidden fields updated:");
    // console.log("selectedDateTarget.value:", this.selectedDateTarget.value);
    // console.log("selectedSlotTarget.value:", this.selectedSlotTarget.value);
    
    // Update summary with beautiful formatting
    const dayName = dateObj.toLocaleDateString('en-US', { weekday: 'long' });
    const dateStr = dateObj.toLocaleDateString('en-US', { month: 'long', day: 'numeric' });
    const slotLabel = button.querySelector('.font-semibold').textContent;
    
    // Session emoji mapping
    const sessionEmoji = {
      'morning': '🌅',
      'afternoon': '☀️', 
      'evening': '🌙'
    };
    
    this.summaryTextTarget.innerHTML = `
      <div class="flex items-center space-x-2">
        <span>${sessionEmoji[session] || '📅'}</span>
        <span>${dayName}, ${dateStr}</span>
      </div>
      <div class="text-sm text-purple-700 mt-1">${slotLabel} (30 minutes)</div>
    `;
    
    // Show summary with animation
    this.summaryTarget.classList.remove('hidden');
    this.summaryTarget.style.opacity = '0';
    this.summaryTarget.style.transform = 'translateY(-10px)';
    
    setTimeout(() => {
      this.summaryTarget.style.transition = 'all 0.3s ease';
      this.summaryTarget.style.opacity = '1';
      this.summaryTarget.style.transform = 'translateY(0)';
    }, 10);
    
    // Revalidate form to potentially enable submit button
    setTimeout(() => this.validateForm(), 100);
    
    // Add pulse animation to button if it gets enabled
    setTimeout(() => {
      if (!this.submitBtnTarget.disabled) {
        this.submitBtnTarget.classList.add('animate-pulse');
        setTimeout(() => {
          this.submitBtnTarget.classList.remove('animate-pulse');
        }, 1000);
      }
    }, 200);
    
    // Scroll to form on mobile
    if (window.innerWidth < 1024) {
      document.querySelector('form').scrollIntoView({ 
        behavior: 'smooth', 
        block: 'nearest' 
      });
    }
  }
}