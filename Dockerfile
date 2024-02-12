FROM debian:10.11

# Menyalin skrip bash ke dalam kontainer
COPY script.sh /script.sh

# Mengatur izin eksekusi untuk skrip bash
RUN chmod +x /script.sh

# Menjalankan skrip bash saat kontainer dimulai
CMD ["/bin/bash", "/script.sh"]
