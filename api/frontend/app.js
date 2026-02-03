const { createApp } = Vue;

createApp({
    data() {
        return {
            operadoras: [],
            page: 1,
            totalPages: 1,
            search: '',
            selectedOp: null,
            chart: null
        }
    },
    mounted() {
        this.fetchData();
    },
    methods: {
        async fetchData() {
            try {
                const res = await axios.get(`http://localhost:8000/api/operadoras?page=${this.page}&search=${this.search}`);
                this.operadoras = res.data.data;
                this.totalPages = Math.ceil(res.data.total / 10);
            } catch (err) {
                console.error(err);
            }
        },
        changePage(step) {
            this.page += step;
            this.fetchData();
        },
        async showDetails(op) {
            this.selectedOp = op;
            try {
                const res = await axios.get(`http://localhost:8000/api/operadoras/${op.CNPJ}`);
                this.$nextTick(() => {
                    this.renderChart(res.data);
                });
            } catch (err) {
                console.error(err);
            }
        },
        renderChart(data) {
            const ctx = document.getElementById('chart').getContext('2d');
            if (this.chart) this.chart.destroy();
            this.chart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: ['Despesas'],
                    datasets: [{
                        label: 'Valor Total',
                        data: [data.ValorDespesas || 0],
                        backgroundColor: 'rgba(54, 162, 235, 0.2)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    scales: { y: { beginAtZero: true } }
                }
            });
        }
    }
}).mount('#app');
