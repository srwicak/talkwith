import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="schedules--bookings"
export default class extends Controller {
  static targets = [
    "calendar",
    "dateInput",
    "eventList",
    "monthYear",
    "scheduleModal",
    "userTimezone",
    "successModal",
    "conflictModal",
    "failedModal",
    "field",
    "error",
    "errorDate",
    "startTime",
    "endTime",
    "errorTime"
  ];
  async connect() {
    this.today = new Date();
    this.currentDate = new Date();
    this.currentMonth = this.today.getMonth();
    this.currentYear = this.today.getFullYear();
    this.tomorrowDate = new Date(this.today.getTime() + 24 * 60 * 60 * 1000);
    this.maxDate = new Date(this.tomorrowDate);
    this.maxDate.setMonth(this.maxDate.getMonth() + 2);

    this.formattedTomorrowDate = `${
      this.tomorrowDate.getMonth() + 1
    }/${this.tomorrowDate.getDate()}/${this.tomorrowDate.getFullYear()}`;

    this.formattedMaxDate = `${
      this.maxDate.getMonth() + 1
    }/${
      this.maxDate.getDate() - 1
    }/${this.maxDate.getFullYear()}`;

    this.userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    this.todayLocalDate = `${this.today.getFullYear()}-${(
      this.today.getMonth() + 1
    )
      .toString()
      .padStart(2, "0")}-${this.today.getDate().toString().padStart(2, "0")}`;

    this.events = [];

    this.dateInputTarget.setAttribute(
      "datepicker-min-date",
      this.formattedTomorrowDate
    );
    this.dateInputTarget.setAttribute(
      "datepicker-max-date",
      this.formattedMaxDate
    );
    await this.loadEvents();
    this.displayEvents(this.todayLocalDate);
    this.userTimezoneTarget.textContent = `${this.userTimezone}`;
  }

  // TODO: multi timezone fetching data
  async loadEvents() {
    const url = `/bookings?month=${this.currentMonth + 1}&year=${
      this.currentYear
    }`;
    const response = await fetch(url);
    if (response.ok) {
      this.events = await response.json();
      this.renderCalendar();
    } else {
      this.events = [];
      this.renderCalendar();
    }
    return Promise.resolve();
  }

  renderCalendar() {
    const firstDay = new Date(this.currentYear, this.currentMonth, 1);
    const lastDay = new Date(this.currentYear, this.currentMonth + 1, 0);

    const firstDayIndex = firstDay.getDay();
    const daysInMonth = lastDay.getDate();

    this.calendarTarget.innerHTML = "";
    this.eventListTarget.innerHTML = "";
    this.monthYearTarget.textContent = firstDay.toLocaleString("default", {
      month: "long",
      year: "numeric",
    });

    // Add empty slots for days of the previous month
    for (let day = 0; day < firstDayIndex; day++) {
      this.calendarTarget.innerHTML += `<div class="h-16"></div>`;
    }

    // Add days of the current month
    for (let day = 1; day <= daysInMonth; day++) {
      const dateString = `${this.currentYear}-${(this.currentMonth + 1)
        .toString()
        .padStart(2, "0")}-${day.toString().padStart(2, "0")}`;

      const eventsForDay = this.events.filter((e) => e.date === dateString);

      this.calendarTarget.innerHTML += `
        <div class="h-16 border rounded flex flex-col items-center justify-center hover:bg-blue-100 dark:bg-gray-600 dark:text-white dark:hover:bg-blue-900 cursor-pointer ${
          eventsForDay.length > 0 ? "bg-blue-200 dark:bg-blue-800" : ""
        } ${
        dateString === this.todayLocalDate ? "border-4 border-blue-500" : ""
      }"
        data-date="${dateString}">
          <span class="font-semibold">${day}</span>
          ${
            eventsForDay.length > 0
              ? `<span class="text-xs text-red-500">(${
                  eventsForDay.length
                } event${eventsForDay.length > 1 ? "s" : ""})</span>`
              : ""
          }
        </div>
      `;
    }

    this.calendarTarget.addEventListener("click", (event) => {
      const dateDiv = event.target.closest("[data-date]");
      if (dateDiv) {
        this.calendarTarget.querySelectorAll("[data-date]").forEach((el) => {
          el.classList.remove("ring", "ring-green-500", "dark:ring-green-400");
        });
        dateDiv.classList.add("ring", "ring-green-500", "dark:ring-green-400");
        this.displayEvents(dateDiv.dataset.date);
      }
    });
  }

  handleClickDate(date) {
    this.displayEvents(date);
  }

  displayEvents(date) {
    this.eventListTarget.innerHTML = "";
    const eventsForDay = this.events.filter((e) => e.date === date);
    if (eventsForDay.length > 0) {

      // Split events into approved and non-approved
      const approvedEvents = eventsForDay.filter((e) => e.approved == true);
      const nonApprovedEvents = eventsForDay.filter((e) => e.approved == false);

      this.eventListTarget.innerHTML = `
        ${
          approvedEvents.length > 0
            ? `
          <div class="approved-events border border-green-500 rounded-lg p-4 mb-4 bg-white dark:bg-gray-800">
            <h3 class="font-bold text-green-600 dark:text-green-400 mb-2">Approved Events</h3>
            <div class="space-y-3">
              ${approvedEvents
                .map(
                  (event) => `
                <div class="p-3 bg-green-50 dark:bg-green-900 rounded-lg shadow">
                  <span class="block font-semibold text-gray-800 dark:text-gray-200">${
                    event.subject
                  }</span>
                  <span class="block text-xs text-gray-500 dark:text-gray-400">${new Date(
                    event.start_time
                  ).toLocaleTimeString()} - ${new Date(
                    event.end_time
                  ).toLocaleTimeString()}</span>
                </div>
              `
                )
                .join("")}
            </div>
          </div>
        `
            : `<p class="text-gray-500 dark:text-gray-400 mb-4"><i>No approved events for this day.</i></p>`
        }

        ${
          nonApprovedEvents.length > 0
            ? `
          <div class="pending-events border border-yellow-500 rounded-lg p-4 bg-white dark:bg-gray-800">
            <h3 class="font-bold text-yellow-600 dark:text-yellow-400 mb-2">Pending/Not Approved Events</h3>
            <div class="space-y-3">
              ${nonApprovedEvents
                .map(
                  (event) => `
                <div class="p-3 bg-yellow-50 dark:bg-yellow-900 rounded-lg shadow">
                  <span class="block font-semibold text-gray-800 dark:text-gray-200">${
                    event.subject
                  }</span>
                  <span class="block text-xs text-gray-500 dark:text-gray-400">${new Date(
                    event.start_time
                  ).toLocaleTimeString()} - ${new Date(
                    event.end_time
                  ).toLocaleTimeString()}</span>
                </div>
              `
                )
                .join("")}
            </div>
          </div>
        `
            : `<p class="text-gray-500 dark:text-gray-400"><i>No pending or not approved events for this day.</i></p>`
        }
      `;
    } else {
      const noEventMessage =
        date === this.todayLocalDate
          ? "No events/schedules for today."
          : "No events/schedules for this day.";
      this.eventListTarget.innerHTML = `<i>${noEventMessage}</i>`;
    }
  }

  now() {
    this.currentMonth = this.today.getMonth();
    this.currentYear = this.today.getFullYear();
    this.loadEvents().then(() => {
      this.displayEvents(this.todayLocalDate);
    });
  }

  previousMonth() {
    this.currentMonth--;
    if (this.currentMonth < 0) {
      this.currentMonth = 11;
      this.currentYear--;
    }
    this.loadEvents().then(() => {
      this.eventListTarget.innerHTML += `<i>Please pick a date</i>`;
    });
  }

  nextMonth() {
    this.currentMonth++;
    if (this.currentMonth > 11) {
      this.currentMonth = 0;
      this.currentYear++;
    }
    this.loadEvents().then(() => {
      this.eventListTarget.innerHTML += `<i>Please pick a date</i>`;
    });
  }

  showFormModal() {
    this.scheduleModalTarget.setAttribute("aria-hidden", "false");
    this.scheduleModalTarget.classList.remove(
      "opacity-0",
      "pointer-events-none"
    );
    this.scheduleModalTarget
      .querySelectorAll("input, select, textarea, button")
      .forEach((el) => {
        el.disabled = false;
      });
    this.scheduleModalTarget.querySelector("form").reset();
  }

  hideFormModal() {
    this.scheduleModalTarget.setAttribute("aria-hidden", "true");
    this.scheduleModalTarget.classList.add("opacity-0", "pointer-events-none");
    this.scheduleModalTarget
      .querySelectorAll("input, select, textarea, button")
      .forEach((el) => {
        el.disabled = true;
      });
    this.scheduleModalTarget.querySelector("form").reset();
  }

  submitAppointment(event) {
    event.preventDefault();

    if (!this.validateForm()) {
      return;
    }

    const form = event.target.closest("form");
    const formData = new FormData(form);

    fetch(form.action, {
      method: form.method,
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body: formData,
    })
      .then((response) => {
        return response.json().then((data) => ({
          status: response.status,
          data,
        }));
      })
      .then(({ status, data }) => {
        if (status === 201) {
          console.log(data);
          this.hideFormModal();
          this.successModalTarget.classList.remove("hidden");
        } else if (status === 409) {
          this.conflictModalTarget.classList.remove("hidden");
        } else {
          this.failedModalTarget.classList.remove("hidden");
        }
      })
      .catch((error) => {
        this.failedModalTarget.classList.remove("hidden");
      });
  }

  validateForm() {
    let isValid = true;
    let dateInput = new Date(this.dateInputTarget.value);
    let startTime = this.startTimeTarget.value;
    let endTime = this.endTimeTarget.value;

    if (!dateInput || !startTime || !endTime) {
      isValid = false;
    }

    if (dateInput < new Date(this.formattedTomorrowDate)) {
      this.errorDateTarget.textContent = `Date must be in the future.`;
      isValid = false;
    } else if (dateInput > new Date(this.formattedMaxDate)) {
      this.errorDateTarget.textContent = `Date must be before ${this.formattedMaxDate}.`;
      isValid = false;
    }

    let start = new Date(`1970-01-01T${startTime}`);
    let end = new Date(`1970-01-01T${endTime}`);

    let duration = (end - start) / 60000;

    if (duration <= 0) {
      this.errorTimeTarget.textContent = `End time must be after start time.`;
      isValid = false;
    } else if (duration < 15) {
      this.errorTimeTarget.textContent = `Duration must be at least 15 minutes.`;
      isValid = false;
    } else if (duration > 120) {
      this.errorTimeTarget.textContent = `Duration must be at most 120 minutes.`;
      isValid = false;
    } else {
      this.errorTimeTarget.textContent = "";
    }

    this.fieldTargets.forEach((field, index) => {
      const error = this.errorTargets[index];
      error.textContent = "";

      if (field.required && !field.value.trim()) {
        error.textContent = `This field is required.`;
        isValid = false;
      }

      if (field.name === "booking[name]" && field.value.length < 3) {
        error.textContent = `Name must be at least 3 characters long.`;
        isValid = false;
      }

      if (field.name === "booking[email]" && field.value) {
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailPattern.test(field.value)) {
          error.textContent = `Email must be a valid email address.`;
          isValid = false;
        }
      }

      if (field.name === "booking[subject]" && field.value.length < 3) {
        error.textContent = `Subject must be at least 3 characters long.`;
        isValid = false;
      }

      if (field.name === "booking[description]" && field.value.length < 20) {
        error.textContent = `Description must be at least 20 characters long.`;
        isValid = false;
      }
      
    });
    return isValid;
  }

  handleSuccess(data) {
    // Modal Success
    const modal = document.getElementById("success-modal");
    const closeModalButton = document.getElementById("close-modal");

    modal.classList.remove("hidden");

    closeModalButton.addEventListener("click", () => {
      modal.classList.add("hidden");
    });
  }

  handleError(error) {
    // Modal Failed
    const modal = document.getElementById("failed-modal");
    const closeModalButton = document.getElementById("close-modal");

    modal.classList.remove("hidden");

    closeModalButton.addEventListener("click", () => {
      modal.classList.add("hidden");
    });
  }

  hideSuccessModal() {
    window.location.reload();
  }

  hideConflictModal() {
    this.conflictModalTarget.classList.add("hidden");
  }

  hideFailedModal() {
    this.failedModalTarget.classList.add("hidden");
  }
}
