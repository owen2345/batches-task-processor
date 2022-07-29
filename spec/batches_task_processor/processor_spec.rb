# frozen_string_literal: true

require 'spec_helper'
describe BatchesTaskProcessor::Processor do
  let(:cache_mock) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let(:inst) { described_class.new }
  before do
    allow(Rails).to receive(:cache).and_return(cache_mock)
    allow(inst).to receive(:calculate_items).and_return([])
    allow(inst).to receive(:process_item).and_return(true)
  end

  describe '#call' do
    before do
      allow(Process).to receive(:spawn)
      allow(Process).to receive(:detach)
    end

    it 'calls #calculate_items to fetch whole items list' do
      expect(inst).to receive(:calculate_items).and_return([])
      inst.call
    end

    it 'initializes the cache' do
      exp_hash = hash_including(:jobs, :count, :date, :finished_jobs, :cancelled)
      expect(cache_mock).to receive(:write).with(anything, exp_hash, anything).and_call_original
      inst.call
    end

    it 'initializes the process for each job' do
      allow(inst).to receive(:per_page).and_return(1)
      allow(inst).to receive(:calculate_items).and_return([1, 2, 3])
      expect(Process).to receive(:spawn).with(include('processor:process_job')).exactly(3).times
      inst.call
    end
  end

  describe '#process_job' do
    let(:job_no) { '0' }
    let(:items) { [1, 2, 3, 4, 5] }
    let(:per_page) { 2 }
    let(:inst) { described_class.new }
    before do
      inst.send(:init_cache)
      allow(inst).to receive(:calculate_items).and_return(items)
      allow(inst).to receive(:per_page).and_return(per_page)
    end

    it 'calls #process_item for each item' do
      allow(inst).to receive(:process_item)
      inst.process_job(job_no)
      expect(inst).to have_received(:process_item).with(items[0])
      expect(inst).to have_received(:process_item).with(items[1])
      expect(inst).to have_received(:process_item).exactly(per_page).times
    end

    it 'calls #preload_job_items to preload items' do
      expect(inst).to receive(:preload_job_items).with(items[0...per_page]).and_call_original
      inst.process_job(job_no)
    end

    it 'stops iteration if process was cancelled' do
      allow(inst).to receive(:process_cancelled?).and_return(true)
      expect(inst).not_to receive(:process_item)
      inst.process_job(job_no)
    end

    describe 'when processing item' do
      it 'does not process item if already processed' do
        processed_value = items[1]
        allow(inst).to receive(:already_processed?).and_call_original
        allow(inst).to receive(:already_processed?).with(job_no.to_i, processed_value).and_return(true)
        expect(inst).not_to receive(:process_item).with(processed_value)
        inst.process_job(job_no)
      end

      it 'updates job cache if item was processed' do
        expect(inst).to receive(:update_job_cache).with(job_no.to_i, anything).exactly(per_page).times
        inst.process_job(job_no)
      end

      it 'updates cache with failed message when failed' do
        some_error = 'some error'
        allow(inst).to receive(:process_item).and_raise(some_error)
        expect(inst).to receive(:update_job_cache).with(job_no.to_i, anything, some_error).exactly(per_page).times
        inst.process_job(job_no)
      end
    end

    it 'marks as finished the job once finished iteration' do
      inst.process_job(job_no)
      expect(inst.send(:main_registry)[:finished_jobs]).to include(job_no.to_i)
    end

    it 'uses activerecord pagination when items is an active collection' do
      mock_items = double('Article', offset: nil, limit: nil)
      allow(inst).to receive(:calculate_items).and_return(mock_items)
      allow(inst).to receive(:process_item)
      expect(mock_items).to receive(:offset).with(per_page).and_return(mock_items)
      expect(mock_items).to receive(:limit).with(per_page).and_return([])
      inst.process_job(1)
    end
  end

  describe '#retry' do
    before do
      allow(Process).to receive(:spawn)
      allow(Process).to receive(:detach)
    end

    it 'initializes the process for each job' do
      allow(inst).to receive(:per_page).and_return(1)
      allow(inst).to receive(:calculate_items).and_return([1, 2, 3])
      inst.send(:init_cache)
      expect(Process).to receive(:spawn).with(include('processor:process_job')).exactly(3).times
      inst.retry
    end
  end

  describe '#status' do
    before { inst.send(:init_cache) }

    it 'prints the status' do
      expect(STDOUT).to receive(:puts).with(include('Process status'))
      inst.status
    end
  end

  describe '#cancel' do
    before { inst.send(:init_cache) }

    it 'marks as cancelled the entire process' do
      inst.cancel
      expect(inst.send(:main_registry)[:cancelled]).to eq(true)
    end
  end

  describe '#clear' do
    before { inst.send(:init_cache) }

    it 'removes the process cache' do
      expect(cache_mock).to receive(:delete)
      inst.clear
    end
  end
end
