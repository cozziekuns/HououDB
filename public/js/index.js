// woooo Spooky global state
let current_specifier_id = 1

Vue.component('hanchan-input', {
  data: function() {
    return {
      count: 0,
    }
  },
  props: ["item"],
  template: `
    <li>
      <button type="button" v-on:click="$emit('remove', item.id)">
        x
      </button>
      {{ item.text }}
      <input type="text" v-bind:name="item.name">
    </li>
  </div>`
})

var app = new Vue({
  el: '#app',
  data: {
    message: 'this is a message',
    specifiers: [{ 
      id: 0, 
      text: 'Player Name:', 
      name: 'player_0',
    }],
  },
  methods: {
    addSpecifier: function() {
      this.specifiers.push({
        id: current_specifier_id,
        text: 'Player Name:',
        name: 'player_' + current_specifier_id.toString(),
      });
      current_specifier_id++;
    },
    removeSpecifier: function(id) {
      let index = this.specifiers.findIndex(specifier => specifier.id === id);
      this.specifiers.splice(index, 1);
    },
  }
});