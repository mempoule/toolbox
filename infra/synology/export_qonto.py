import requests
import json
import pathlib
import csv
import sys

querystring = {"iban": "XXXXXX"}

headers = {
    "Content-Type": "application/json",
    "Authorization": "XXXXXX:XXXXXX"
}


def get_attachment_folder(label):
    if "AMAZON".lower() in label.lower() or "Amzn Mktp".lower() in label.lower():
        return "AMAZON"
    elif "Rue du Commerce".lower() in label.lower():
        return "RUEDUCOMMERCE"
    elif "LA POSTE".lower() in label.lower():
        return "LAPOSTE"
    elif "Sedomicilier".lower() in label.lower():
        return "SEDOMICILIER"
    elif "Paypal".lower() in label.lower():
        return "PAYPAL"
    elif "Vistaprint".lower() in label.lower():
        return "VISTAPRINT"
    elif "Paddle".lower() in label.lower():
        return "PADDLE"
    elif "Sncf".lower() in label.lower():
        return "TRANSPORT"
    elif "Aprr".lower() in label.lower() or "Autoroutes du S".lower() in label.lower():
        return "PEAGE"
    elif "Bouygues Telecom".lower() in label.lower() or "Free Telecom".lower() in label.lower() or "Free HautDebit".lower() in label.lower():
        return "TELEPHONIE"
    elif "Metro".lower() in label.lower():
        return "METRO"
    elif "Castorama".lower() in label.lower():
        return "BRICOLAGE"
    elif "Cdiscount".lower() in label.lower():
        return "CDISCOUNT"
    elif "Ikea".lower() in label.lower():
        return "AMEUBLEMENT"
    elif "Ovh SAS".lower() in label.lower():
        return "HOSTING"
    elif "Qonto".lower() in label.lower():
        return "BANQUE"
    elif "Musee des beaux arts L".lower() in label.lower():
        return "STATIONNEMENT"
    else:
        return "AUTRES"


#csv_dir = 'D:/temp/attachments'
#attachments_dir = 'D:/temp/attachments'

csv_dir = 'XXXXXX'
attachments_dir = 'XXXXXX'


invoices_file = pathlib.Path(f'{csv_dir}/invoices.csv')
invoices_header = ['status', 'emitted_at', 'side', 'operation_type', 'amount',
                   'currency',
                   'vat_amount', 'settled_balance', 'category', 'note', 'attachment_filenames', 'label',
                   'id', 'transaction_id']
invoices_file.touch(exist_ok=True)
invoices_csv = open(invoices_file, 'w', newline='')
invoices_writer = csv.writer(invoices_csv)
invoices_writer.writerow(invoices_header)

inventory_file = pathlib.Path(f'{csv_dir}/inventory.csv', newline='')
inventory_header = ['emitted_at', 'amount', 'currency',
                    'vat_amount', 'category', 'note', 'attachment_filenames', 'id', 'transaction_id']
inventory_file.touch(exist_ok=True)
inventory_csv = open(inventory_file, 'w')
inventory_writer = csv.writer(inventory_csv)
inventory_writer.writerow(inventory_header)


transactions_url = "https://thirdparty.qonto.com/v2/transactions"

transactions = requests.request("GET", transactions_url, headers=headers, params=querystring).json()

for transaction in transactions['transactions']:
    attachment_filenames = []
    id = transaction['id']
    transaction_id = transaction['transaction_id']
    amount = transaction['amount']
    side = transaction['side']
    operation_type = transaction['operation_type']
    currency = transaction['currency']
    label = transaction['label']
    emitted_at = transaction['emitted_at'][:10]
    status = transaction['status']
    vat_amount = transaction['vat_amount']
    category = get_attachment_folder(transaction['label'])
    note = transaction['note']
    if note is not None:
        note = note.replace('\n', ' - ')
    settled_balance = transaction['settled_balance']
    if len(transaction['attachment_ids']) > 0:
        pathlib.Path(f'{attachments_dir}/{category}').mkdir(parents=True, exist_ok=True)
        for attachment_id in transaction['attachment_ids']:
            attachment_qry = f"https://thirdparty.qonto.com/v2/attachments/{attachment_id}"
            response_attachment_query = requests.request("GET", attachment_qry, headers=headers).json()
            attachment_url = response_attachment_query['attachment']['url']
            attachment_filenames.append(response_attachment_query['attachment']['file_name'])
            r_attachment = requests.get(attachment_url)
            with open(f"{attachments_dir}/{category}/{response_attachment_query['attachment']['file_name']}", 'wb') as f_attachment:
                f_attachment.write(r_attachment.content)

    invoices_data = [status, emitted_at, side, operation_type, amount, currency, vat_amount, settled_balance, category, note, attachment_filenames, label, id, transaction_id]
    invoices_writer.writerow(invoices_data)

    if category in ["AMAZON", "BRICOLAGE", "CDISCOUNT", "AMEUBLEMENT", "RUEDUCOMMERCE"] and operation_type in ['direct_debit', 'card']:
        inventory_data = [emitted_at, amount, currency, vat_amount, category, note, attachment_filenames, id, transaction_id]
        inventory_writer.writerow(inventory_data)


invoices_csv.close()
inventory_csv.close()
